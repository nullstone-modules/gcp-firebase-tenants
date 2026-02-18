variable "tenants" {
  type = list(object({
    display_name : string
    disable_auth : bool
  }))
  default = []

  description = <<EOF
A list of tenants to configure in Firebase Auth.
These tenants will be able to log in to the Astraeus platform.
EOF
}
