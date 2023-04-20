## enable Workload Identity to Harness Delegate SA

# Google Service Account will be used when annotating the Kubernetes Service Account to do Workload Identity
resource "google_service_account" "harness_delegate_sa" {
  account_id   = "harness-delegate"
  display_name = "Google Service Account that will be used for Harness CI Workload Identity use cases"
}

# Binding roles/iam.workloadIdentityUser role to Google Service Account harness-delegate
resource "google_service_account_iam_binding" "harness_delegate_workload_identity_iam" {
  service_account_id = google_service_account.harness_delegate_sa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "serviceAccount:${var.gcp_project}.svc.id.goog[${var.harness_delegate_namespace}/${var.harness_delegate_name}-delegate]",
    "serviceAccount:${var.gcp_project}.svc.id.goog[${var.builder_namespace}/${var.builder_ksa}]",
  ]
}

# Adding permission to push container images to Google Artifact Registry using 
# the harness-delegate Service Account
resource "google_project_iam_member" "iam_binding_gar_push_repo_admin" {
  project = var.gcp_project
  role    = "roles/artifactregistry.createOnPushRepoAdmin"
  member  = google_service_account.harness_delegate_sa.member

}

# Adding permission to perform activties as k8s cluster adminstrator
# allowing to create cluster roles/bindings and other setup admin activities
resource "google_project_iam_member" "iam_member_container_admin" {
  project = var.gcp_project
  role    = "roles/container.admin"
  member  = google_service_account.harness_delegate_sa.member
}

# Install Harness Delegate using harness-delegate-ng helm chart
# This install happens if and only if install_harness_delegate is true
resource "helm_release" "harness_delegate" {
  depends_on = [
    google_container_cluster.primary,
    google_service_account.harness_delegate_sa
  ]

  name             = "${var.harness_delegate_name}-release"
  repository       = "https://app.harness.io/storage/harness-download/delegate-helm-chart/"
  chart            = "harness-delegate-ng"
  namespace        = var.harness_delegate_namespace
  create_namespace = true

  set {
    name  = "upgrader.enabled"
    value = "false"
  }

  set_sensitive {
    name  = "accountId"
    value = var.harness_account_id
  }

  set_sensitive {
    name  = "delegateToken"
    value = var.harness_delegate_token
  }

  set {
    name  = "delegateName"
    value = var.harness_delegate_name
  }
  set {
    name  = "managerEndpoint"
    value = var.harness_manager_endpoint
  }
  set {
    name  = "delegateDockerImage"
    value = var.harness_delegate_image
  }
  set {
    name  = "replicas"
    value = var.harness_delegate_replicas
  }

  # Enables Workload Identity for the Delegate SA
  set {
    name  = "serviceAccount.annotations.iam\\.gke\\.io\\/gcp-service-account"
    value = google_service_account.harness_delegate_sa.email
  }
}

# Create harness-builder Kubernetes Service Account that will be used
# by Harness Pipeline delegate pods.
# This create happens if and only if install_harness_delegate is true
resource "kubectl_manifest" "create_builder_sa" {
  depends_on = [
    google_container_cluster.primary
  ]
  yaml_body = templatefile("${path.module}/templates/builder-sa.tfpl", {
    serviceAccountName        = "${var.builder_ksa}"
    serviceAccountNamespace   = "${var.builder_namespace}"
    googleServiceAccountEmail = "${google_service_account.harness_delegate_sa.email}"
  })
}

