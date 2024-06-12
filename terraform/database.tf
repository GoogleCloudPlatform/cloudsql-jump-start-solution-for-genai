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

resource "random_password" "default" {
  length = 16
}

resource "google_sql_database_instance" "default" {
  project          = var.google_cloud_db_project
  database_version = "POSTGRES_16"
  name             = "toys-inventory"
  region           = var.google_cloud_default_region
  root_password    = random_password.default.result
  settings {
    edition           = "ENTERPRISE_PLUS"
    tier              = "db-perf-optimized-N-8" # 8 vCPU, 64GB RAM
    availability_type = "REGIONAL"
    disk_size         = 250
    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }
    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
    ip_configuration {
      ssl_mode = "ENCRYPTED_ONLY"
      psc_config {
        psc_enabled = true
        allowed_consumer_projects = [
          var.google_cloud_run_project
        ]
      }
      ipv4_enabled = false
    }
    data_cache_config {
      data_cache_enabled = true
    }
  }
  # Note: in production environments, this setting should be true to prevent
  # accidental deletion. Set it to false to make tf apply and destroy work
  # quickly.
  deletion_protection = false
}

resource "google_sql_user" "iam_sa_user" {
  name     = local.iam_sa_username
  instance = google_sql_database_instance.default.name
  type     = "CLOUD_IAM_SERVICE_ACCOUNT"
  project  = var.google_cloud_db_project
}

resource "google_sql_database" "default" {
  name     = "retail"
  instance = google_sql_database_instance.default.name
  project  = var.google_cloud_db_project
}
