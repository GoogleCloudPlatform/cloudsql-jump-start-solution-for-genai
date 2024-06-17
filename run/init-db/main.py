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

import asyncio
import os

import asyncpg

DB_HOST = os.getenv("DB_HOST")
DB_USER = os.getenv("DB_USER")
DB_NAME = os.getenv("DB_NAME")
DB_PASS = os.getenv("DB_PASS")
APP_USER = os.getenv("APP_USER")


async def main():
    print("Running init-db job...")
    sys_conn = await asyncpg.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        ssl="require",
    )
    print("Granting privileges on database...")
    print("Granting privileges on public schema...")
    print("Creating extension...")
    await sys_conn.execute(
        f"""
        GRANT ALL PRIVILEGES ON DATABASE "{DB_NAME}" TO "{APP_USER}";
        GRANT ALL ON SCHEMA public TO "{APP_USER}";
        CREATE EXTENSION IF NOT EXISTS vector;
        """
    )
    await sys_conn.close()
    print("Done")


if __name__ == "__main__":
    asyncio.run(main())
