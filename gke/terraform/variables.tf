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

variable "google_cloud_db_project" {
  description = "Google Cloud Project for the Cloud SQL instance"
  type        = string
}

variable "google_cloud_k8s_project" {
  description = "Google Cloud Project for the K8s cluster"
  type        = string
}

variable "google_cloud_default_region" {
  description = "The default region to use when no other is set"
  default     = "us-central1"
  type        = string
}

variable "create_bastion" {
  description = "Creation a Bastion instance for debugging"
  default     = false
}
