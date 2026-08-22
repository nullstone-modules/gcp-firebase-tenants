// Seeds superuser accounts directly into Identity Platform.
//
// The app's user-provisioning endpoints all require an already-authenticated
// privileged user, so a new environment has no way to create its first one.
// Identity Platform accounts are data-plane objects with no native Terraform
// resource, so we call accounts:batchCreate through terracurl.
//
// batchCreate sets the account and its custom claims in one atomic call and
// skips accounts that already exist, which is what makes this declarative.

// Reuses the credentials the google provider is already configured with.
data "google_client_config" "default" {}

locals {
  // One seed per (tenant, email). Keyed by display_name (known at plan time);
  // the server-generated tenant id is not.
  superuser_seeds = {
    for pair in setproduct(keys(local.tenants), var.superusers) :
    "${pair[0]}:${pair[1]}" => {
      tenant_key = pair[0]
      email      = pair[1]
      // Namespaced uid, so seeded accounts can never collide with the random
      // uids the app's own user-creation path produces.
      local_id = "tfseed-${substr(sha1("${pair[0]}:${pair[1]}"), 0, 24)}"
    }
  }
}

// An account with no tenant claim cannot sign in; the app rejects those tokens.
check "superusers_require_tenants" {
  assert {
    condition     = length(var.superusers) == 0 || length(local.tenants) > 0
    error_message = "`superusers` is set, but no tenants are managed. Superusers are seeded per tenant, so nothing was seeded. Add a tenant to `tenants`."
  }
}

resource "terracurl_request" "superuser" {
  for_each = local.superuser_seeds

  name   = "seed-superuser-${each.key}"
  method = "POST"
  url    = "https://identitytoolkit.googleapis.com/v1/projects/${local.project_id}/tenants/${google_identity_platform_tenant.tenant[each.value.tenant_key].name}/accounts:batchCreate"

  headers = {
    "Authorization" = "Bearer ${data.google_client_config.default.access_token}"
    "Content-Type"  = "application/json"
  }

  // Exactly one user per request. Duplicates within a single batch cause the
  // whole batch to be rejected; duplicates against existing accounts only skip
  // that user.
  request_body = jsonencode({
    allowOverwrite = false
    sanityCheck    = true
    users = [{
      localId       = each.value.local_id
      email         = each.value.email
      emailVerified = true
      // Custom claims are a JSON string, not an object.
      customAttributes = jsonencode({ role = ["superuser"] })
    }]
  })

  // Do not widen. A 4xx means the request was malformed, not that a user was
  // skipped; skipped users are reported in the body of a 200.
  response_codes = ["200"]

  // The app owns role changes after creation. Never read (no drift fighting)
  // and never delete (removing an email must not demote anyone).
  skip_read    = true
  skip_destroy = true

  lifecycle {
    // The access token rotates hourly and would otherwise plan a replacement
    // on every run.
    ignore_changes = [headers]
  }
}

output "superuser_seed_errors" {
  description = <<EOF
Per-user seeding errors, keyed by "<tenant>:<email>".
This is the only signal for a failed seed: batchCreate returns 200 even when a
user is not created, so an apply will not fail. An "already exists" entry is the
expected no-op; anything else means that user was not created.
EOF

  value = {
    for key, request in terracurl_request.superuser : key => [
      for err in try(jsondecode(request.response).error, []) : err.message
    ] if length(try(jsondecode(request.response).error, [])) > 0
  }
}
