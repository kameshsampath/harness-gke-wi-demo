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

