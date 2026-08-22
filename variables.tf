variable "tenants" {
  type = list(object({
    display_name : string
    disable_auth : bool
    enable_google_idp : optional(bool, true)
    enable_microsoft_idp : optional(bool, true)
  }))
  default = []

  description = <<EOF
A list of tenants to configure in Firebase Auth.
These tenants will be able to log in to the Astraeus platform.
EOF
}

variable "superusers" {
  type    = list(string)
  default = []

  description = <<EOF
A list of user emails to seed with the `superuser` role in every managed tenant.
This exists to bootstrap a new environment: the app's user-provisioning endpoints
require an already-authenticated privileged user.

Create-only. An account that already exists is left untouched, whatever its
current role, and removing an email from this list never deletes or demotes
anyone. The app owns roles after creation.

Individual emails only. Google Group addresses are not accepted: a group is not
a signable-in identity, and expanding one would ratchet access, since joining
would grant it and leaving would never revoke it.
EOF
}
