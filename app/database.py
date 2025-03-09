import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base

LOCAL_DATABASE_URL = "postgresql://trung:root@localhost:5432/todos"

DATABASE_URL = os.getenv("DATABASE_URL", LOCAL_DATABASE_URL)

engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()