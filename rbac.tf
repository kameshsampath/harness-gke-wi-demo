resource "google_service_account" "translator_sa" {
  count        = var.app_use_workload_identity ? 1 : 0
  account_id   = "translator"
  display_name = "Service Account that will be used to call Translate API"
}

resource "google_service_account_iam_binding" "workload_identity_iam" {
  count              = var.app_use_workload_identity ? 1 : 0
  service_account_id = google_service_account.translator_sa[0].name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.gcp_project}.svc.id.goog[${var.app_namespace}/${var.app_ksa}]",
  ]
}

resource "google_project_iam_member" "iam_binding_translate_users" {
  count   = var.app_use_workload_identity ? 1 : 0
  project = var.gcp_project
  role    = "roles/cloudtranslate.user"
  member = "${google_service_account.translator_sa[0].member}"
}

## Permissions for FluxCD to read from GAR
resource "google_service_account" "gar_reader_sa" {
  account_id   = "gar-reader"
  display_name = "Service Account that will be used to download artifacts from GAR"
}

resource "google_service_account_iam_binding" "workload_identity_gar_iam" {
  service_account_id = google_service_account.gar_reader_sa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.gcp_project}.svc.id.goog[${var.flux_system_namespace}/${var.flux_source_controller_ksa}]",
  ]
}

resource "google_project_iam_member" "iam_binding_gar_reader" {
  project = var.gcp_project
  role    = "roles/artifactregistry.reader"
  member  = "${google_service_account.gar_reader_sa.member}"
}
