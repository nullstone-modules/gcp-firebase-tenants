locals {
  tenants = { for tenant in var.tenants : tenant.display_name => tenant }
}

resource "google_identity_platform_tenant" "tenant" {
  for_each = local.tenants

  project                  = local.project_id
  display_name             = each.key
  disable_auth             = each.value.disable_auth
  allow_password_signup    = false
  enable_email_link_signin = false

  client {
    permissions {
      disabled_user_deletion = false
      disabled_user_signup   = false
    }
  }
}
