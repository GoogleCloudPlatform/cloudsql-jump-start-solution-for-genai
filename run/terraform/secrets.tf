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


# --------- Secrets for the init-db job ---------

# Create db_admin_user secret
resource "google_secret_manager_secret" "db_admin_user" {
  project   = var.google_cloud_run_project
  secret_id = "db-admin-user"
  replication {
    auto {}
  }
}

# Attaches secret data for db_admin_user secret
resource "google_secret_manager_secret_version" "db_admin_user_data" {
  secret      = google_secret_manager_secret.db_admin_user.name
  secret_data = "postgres" # Stores secret as a plain txt in state file
}

# Create db_admin_pass secret
resource "google_secret_manager_secret" "db_admin_pass" {
  project   = var.google_cloud_run_project
  secret_id = "db-admin-pass"
  replication {
    auto {}
  }
}

# Attaches secret data for db_admin_pass secret
resource "google_secret_manager_secret_version" "db_admin_pass_data" {
  secret      = google_secret_manager_secret.db_admin_pass.name
  secret_data = random_password.default.result
}

# --------- Secrets for the load-embeddings job and chatbot service ---------

# Create db_host secret
resource "google_secret_manager_secret" "db_host" {
  project   = var.google_cloud_run_project
  secret_id = "db-host"
  replication {
    auto {}
  }
}

# Attaches secret data for db_host secret
resource "google_secret_manager_secret_version" "db_host_data" {
  secret      = google_secret_manager_secret.db_host.name
  secret_data = google_sql_database_instance.default.dns_name
}

# Create db_iam_user secret
resource "google_secret_manager_secret" "db_iam_user" {
  project   = var.google_cloud_run_project
  secret_id = "db-iam-user"
  replication {
    auto {}
  }
}

# Attaches secret data for db_iam_user secret
resource "google_secret_manager_secret_version" "db_iam_user_data" {
  secret      = google_secret_manager_secret.db_iam_user.name
  secret_data = local.iam_sa_username
}

# Create db_name secret
resource "google_secret_manager_secret" "db_name" {
  project   = var.google_cloud_run_project
  secret_id = "db-name"
  replication {
    auto {}
  }
}

# Attaches secret data for db_name secret
resource "google_secret_manager_secret_version" "db_name_data" {
  secret      = google_secret_manager_secret.db_name.name
  secret_data = google_sql_database.default.name
}
