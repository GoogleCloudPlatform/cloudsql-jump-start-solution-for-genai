#!/usr/bin/env python3
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


import sys


def prepare_template(filename, project_name, region="us-central1"):
    lines = []
    with open(filename, "r") as fin:
        for line in fin:
            if "__PROJECT__" in line:
                line = line.replace("__PROJECT__", project_name)
            if "__REGION__" in line:
                line = line.replace("__REGION__", region)
            lines.append(line)
    with open(filename, "w") as fout:
        fout.writelines(lines)


yaml_templates = [
    "chatbot-api/k8s/deployment.yaml",
    "init-db/k8s/job.yaml",
    "load-embeddings/k8s/job.yaml",
]

for t in yaml_templates:
    if len(sys.argv) == 3:
        prepare_template(t, sys.argv[1], sys.argv[2])
    else:
        prepare_template(t, sys.argv[1])
