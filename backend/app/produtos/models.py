from sqlalchemy import Boolean, Column, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from ..database import Base


class Produto(Base):
    """A TABELA. Nao confunda com os schemas: aquilo atravessa a
    fronteira da API, isto vira linha no banco.
    """

    __tablename__ = "produtos"

    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String(120), nullable=False)
    preco = Column(Float, nullable=False)
    em_estoque = Column(Boolean, nullable=False, default=True)

    dono_id = Column(
        Integer, ForeignKey("usuarios.id", name="fk_produtos_dono"), nullable=True
    )
    dono = relationship("Usuario", back_populates="produtos")