variable "tenants" {
  type = list(object({
    display_name : string
    disable_auth : bool
    enable_google_idp : optional(bool, true)
  }))
  default = []

  description = <<EOF
A list of tenants to configure in Firebase Auth.
These tenants will be able to log in to the Astraeus platform.
EOF
}
