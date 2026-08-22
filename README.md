# gcp-firebase-tenants
Configure tenants in a Firebase project.

## Seeding superusers

Bootstraps the first privileged accounts in a new environment. The app's
user-provisioning endpoints require an already-authenticated privileged user, so
without this there is no way to create one. Each email is seeded into every
managed tenant with a `superuser` role claim.

```hcl
tenants = [
  { display_name = "acme", disable_auth = false },
]

superusers = [
  "ada@example.com",
  "grace@example.com",
]
```

Individual emails only — Google Group addresses are not accepted.

### Behavior

- **Create-only.** An existing account is skipped, whatever its current role.
  The app owns roles after creation.
- **Never deletes.** Removing an email from the list, or destroying the module,
  leaves the account in place.
- **No drift fighting.** The app mutates these claims at runtime and Terraform
  will not reconcile them.
- Requires at least one tenant. A tenant-less account cannot sign in, so with no
  tenants nothing is seeded and a `check` warns.
- Writes only to Identity Platform. If the app keeps its own tenant registry
  (e.g. for email-first tenant lookup at login), that still requires the app's
  onboarding path.

### Check the output

**An apply will not fail when a user fails to seed.** The API returns `200` even
then, reporting failures in its response body. Read `superuser_seed_errors`,
keyed by `"<tenant>:<email>"`, after every apply. An "already exists" entry is
the expected no-op; anything else (a typo'd email, say) means that user was not
created.

### Re-seeding

To retry a user, taint the request so it is sent again:

```bash
tofu apply -replace='terracurl_request.superuser["<tenant>:<email>"]'
```
