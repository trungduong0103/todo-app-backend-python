from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import Annotated
import models
from database import engine, SessionLocal
from sqlalchemy.orm import Session

app = FastAPI()
models.Base.metadata.create_all(bind=engine)


class TodoBase(BaseModel):
    name: str
    description: str
    is_completed: bool


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


db_dependency = Annotated[Session, Depends(get_db)]

@app.get("/")
async def root():
    return {"message": "FastAPI with PostgreSQL"}

@app.post("/todos/")
async def create_todo(todo: TodoBase, db: db_dependency):
    db_todo = models.Todos(
        name=todo.name, description=todo.description, is_completed=todo.is_completed
    )
    db.add(db_todo)
    db.commit()
    db.refresh(db_todo)

    return db_todo
 