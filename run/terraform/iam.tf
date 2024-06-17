/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# --------- Cloud Run service account ---------
resource "google_service_account" "run_sa" {
  project      = var.google_cloud_run_project
  account_id   = "cloud-run-sa"
  display_name = "Custom SA for Cloud Run Service"
}

resource "google_project_iam_member" "database_access" {
  project = var.google_cloud_db_project
  role    = "roles/cloudsql.instanceUser"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_project_iam_member" "aiplatform_user" {
  project = var.google_cloud_db_project
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_project_iam_member" "secret_manager_access" {
  project = var.google_cloud_db_project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

# --------- Cloud Build service account ---------
resource "google_service_account" "build_sa" {
  project      = var.google_cloud_run_project
  account_id   = "cloud-build-sa"
  display_name = "Custom SA for Cloud Build"
}

resource "google_project_iam_member" "logs_writer" {
  project = var.google_cloud_run_project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.build_sa.email}"
}

resource "google_project_iam_member" "storage_admin" {
  project = var.google_cloud_run_project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.build_sa.email}"
}

resource "google_project_iam_member" "registry_writer" {
  project = var.google_cloud_run_project
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.build_sa.email}"
}
