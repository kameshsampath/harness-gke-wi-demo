output "gcp_region" {
  value       = var.gcp_region
  description = "GCloud gcp_region"
}

output "gcp_project" {
  value       = var.gcp_project
  description = "Google Cloud Project ID"
  sensitive   = true
}

output "zone" {
  value       = local.google_zone
  description = "Google Cloud Zone"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}

output "translator_service_account" {
  value       = length(google_service_account.translator_sa) == 0 ? "" : google_service_account.translator_sa[0].email
  description = "The Google Service Account 'translator'"
}

output "harness_delegate_service_account" {
  value       = length(google_service_account.harness_delegate_sa) == 0 ? "" : google_service_account.harness_delegate_sa.email
  description = "The Google Service Account 'harness-delegate' that will be used with 'harness-builder' Kubernetes SA"
}

output "ksa_patch" {
  value = templatefile("templates/sa.tfpl", {
    serviceAccountName : "${var.app_ksa}"
    serviceAccountNamespace : "${var.app_namespace}",
    googleServiceAccountEmail : "${google_service_account.translator_sa[0].email}"
  })
}





