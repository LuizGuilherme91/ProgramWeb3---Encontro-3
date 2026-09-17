from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship

from ..database import Base


class Usuario(Base):
    """A TABELA de usuarios."""

    __tablename__ = "usuarios"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(80), nullable=False)
    email = Column(String(120), nullable=False, unique=True, index=True)
    senha_hash = Column(String(100), nullable=False)

    produtos = relationship("Produto", back_populates="dono")