import os
from contextlib import asynccontextmanager

import psycopg
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel


def connect():
    return psycopg.connect(os.environ["DATABASE_URL"])


@asynccontextmanager
async def lifespan(app: FastAPI):
    with connect() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS products (
                id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                name TEXT NOT NULL,
                price DOUBLE PRECISION NOT NULL
            )
        """)
    yield


app = FastAPI(title="Products REST API", lifespan=lifespan)


class Product(BaseModel):
    name: str
    price: float


@app.get("/health")
def health():
    with connect() as conn:
        conn.execute("SELECT 1")
    return {"status": "ok"}


@app.get("/products")
def get_products():
    with connect() as conn:
        return [
            {"id": row[0], "name": row[1], "price": row[2]}
            for row in conn.execute(
                "SELECT id, name, price FROM products ORDER BY id"
            ).fetchall()
        ]


@app.post("/products", status_code=201)
def add_product(product: Product):
    with connect() as conn:
        row = conn.execute(
            "INSERT INTO products (name, price) VALUES (%s, %s) RETURNING id",
            (product.name, product.price),
        ).fetchone()
        return {"id": row[0], **product.model_dump()}


@app.put("/products/{product_id}")
def update_product(product_id: int, product: Product):
    with connect() as conn:
        row = conn.execute(
            "UPDATE products SET name=%s, price=%s WHERE id=%s RETURNING id",
            (product.name, product.price, product_id),
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="Not found")
        return {"id": row[0], **product.model_dump()}


@app.delete("/products/{product_id}")
def delete_product(product_id: int):
    with connect() as conn:
        row = conn.execute(
            "DELETE FROM products WHERE id=%s RETURNING id",
            (product_id,),
        ).fetchone()
        if row is None:
            raise HTTPException(status_code=404, detail="Not found")
        return {"deleted": True}
