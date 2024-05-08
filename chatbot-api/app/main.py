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
from contextlib import asynccontextmanager
import os
from typing import Union

import asyncpg
from fastapi import FastAPI, Request
import google.auth
from google.auth.transport.requests import Request as GRequest
from google.cloud import aiplatform
from langchain.chains.summarize import load_summarize_chain
from langchain_core.documents import Document
from langchain_core.prompts import PromptTemplate
from langchain_google_vertexai import VertexAI, VertexAIEmbeddings
from pgvector.asyncpg import register_vector


REGION = os.getenv("REGION")
PROJECT_ID = os.getenv("PROJECT_ID")
DB_HOST = os.getenv("DB_HOST")
DB_USER = os.getenv("DB_USER")
DB_NAME = os.getenv("DB_NAME")

aiplatform.init(project=f"{PROJECT_ID}", location=f"{REGION}")
llm = VertexAI()
embeddings_service = VertexAIEmbeddings(
    model_name="textembedding-gecko@003",
)


async def find_by_query(pool, q):
    """
    Finding similar toy products using pgvector cosine search operator
    """

    min_price = 25
    max_price = 100
    similarity_threshold = 0.1
    num_matches = 25

    qe = embeddings_service.embed_query(q)

    async with pool.acquire() as conn:
        await register_vector(conn)

        # Find similar products to the query using cosine similarity search
        # over all vector embeddings.
        # This new feature is provided by `pgvector`.
        results = await conn.fetch(
            """
            WITH vector_matches AS (
              SELECT product_id, 1 - (embedding <=> $1) AS similarity
              FROM product_embeddings
              WHERE 1 - (embedding <=> $1) > $2
              ORDER BY similarity DESC
              LIMIT $3
            )
            SELECT product_name, list_price, description FROM products
            WHERE product_id IN (SELECT product_id FROM vector_matches)
            AND list_price >= $4 AND list_price <= $5
            """,
            qe,
            similarity_threshold,
            num_matches,
            min_price,
            max_price,
        )

        if len(results) == 0:
            raise Exception("Did not find any results. Adjust the query parameters.")

        matches = []
        for r in results:
            # Collect the description for all the matched similar toy products.
            matches.append(
                {
                    "product_name": r["product_name"],
                    "description": r["description"],
                    "list_price": round(r["list_price"], 2),
                }
            )
        return matches


map_prompt_template = """
You will be given a detailed description of a toy product.
This description is enclosed in triple backticks (```).
Using this description only, extract the name of the toy,
the price of the toy and its features.

```{text}```
SUMMARY:
"""

combine_prompt_template = """
You will be given a detailed description different toy products
enclosed in triple backticks (```) and a question enclosed in
double backticks(``).

Select one toy that is most relevant to answer the question.
Using that selected toy description, answer the following
question in as much detail as possible.

You should only use the information in the description.
Your answer should include the name of the toy, the price of the toy
and its features. Your answer should be less than 200 words.
Your answer should be in Markdown in a numbered list format.

Description:
```{text}```


Question:
``{user_query}``


Answer:
"""


async def find_by_chatbot(pool, q):
    matches = await find_by_query(pool, q)

    map_prompt = PromptTemplate(
        template=map_prompt_template,
        input_variables=["text"],
    )

    combine_prompt = PromptTemplate(
        template=combine_prompt_template,
        input_variables=["text", "user_query"],
    )

    matches = [
        f"""
        The name of the toy is {r["product_name"]}.
        The price of the toy is ${round(r["list_price"], 2)}.
        Its description is below:
        {r["description"]}.
        """
        for r in matches
    ]

    docs = [Document(page_content=t) for t in matches]
    chain = load_summarize_chain(
        llm,
        chain_type="map_reduce",
        map_prompt=map_prompt,
        combine_prompt=combine_prompt,
    )
    answer = chain.invoke(
        {
            "input_documents": docs,
            "user_query": q,
        }
    )
    return {"answer": answer["output_text"]}


creds, _ = google.auth.default(
    scopes=["https://www.googleapis.com/auth/sqlservice.login"]
)


def get_password():
    if not creds.valid:
        request = GRequest()
        creds.refresh(request)

    return creds.token


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.pool = await asyncpg.create_pool(
        host=DB_HOST,
        user=DB_USER,
        password=get_password,
        database=DB_NAME,
        ssl="require",
    )
    yield
    await asyncio.wait_for(app.state.pool.close(), 10)


app = FastAPI(lifespan=lifespan)


@app.get("/search")
async def do_search(request: Request, q: Union[str, None] = None):
    return await find_by_query(request.app.state.pool, q)


@app.get("/chatbot")
async def ask_chatbot(request: Request, q: Union[str, None] = None):
    return await find_by_chatbot(request.app.state.pool, q)


@app.get("/")
async def root(request: Request):
    async with request.app.state.pool.acquire() as conn:
        version = await conn.fetch("select version()")
        return version[0]
