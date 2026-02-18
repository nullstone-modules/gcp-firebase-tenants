data "google_project" "this" {}

locals {
  project_id     = data.google_project.this.project_id
  project_number = data.google_project.this.number
}

resource "google_project_service" "firebase" {
  service                    = "firebase.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}
