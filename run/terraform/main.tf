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

locals {
  network_name = "production-network"
  subnet_name = "run-subnet"

  subnet_names = [
    for subnet_self_link in module.gcp_network.subnets_self_links :
    split("/", subnet_self_link)[length(split("/", subnet_self_link)) - 1]
  ]

  iam_sa_username = trimsuffix(
    google_service_account.run_sa.email,
    ".gserviceaccount.com",
  )
}
