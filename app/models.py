from sqlalchemy import Boolean, Column, Integer, String

from database import Base

class Todos(Base):
    __tablename__ = "todos"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(String)
    is_completed = Column(Boolean, default=False)

