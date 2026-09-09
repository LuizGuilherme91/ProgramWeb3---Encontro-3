import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

load_dotenv()

URL = os.environ["DATABASE_URL"]

ARGS = {"check_same_thread": False} if URL.startswith("sqlite") else {}

engine = create_engine(URL, connect_args=ARGS)
SessionLocal = sessionmaker(bind=engine, autoflush=False)

class Base(DeclarativeBase):
    """Todas as tabelas herdam daqui. E assim que o SQLAlchemy
    descobre quais existem.
    """

def get_db():
    """Uma sessao por requisicao, fechada mesmo se der erro."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()