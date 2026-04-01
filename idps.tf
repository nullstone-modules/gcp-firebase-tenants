data "ns_connection" "google_idp" {
  name     = "google-idp"
  contract = "datastore/gcp/firebase"
}

locals {
  google_client_id               = data.ns_connection.google_idp.outputs.client_id
  google_client_secret_secret_id = data.ns_connection.google_idp.outputs.client_secret_secret_id
  google_client_secret           = data.google_secret_manager_secret_version.client_secret.secret_data
}

data "google_secret_manager_secret_version" "client_secret" {
  secret = local.google_client_secret_secret_id
}
