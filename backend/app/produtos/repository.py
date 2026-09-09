from sqlalchemy.orm import Session

from .models import Produto

def listar(db: Session):
    return db.query(Produto).all()

def buscar(db: Session, produto_id: int):
    return db.query(Produto).filter(Produto.id == produto_id).first()

def criar(db: Session, dados: dict):
    produto = Produto(**dados)
    db.add(produto)
    db.commit()
    db.refresh(produto)  
    return produto

def buscar_por_nome(db: Session, nome: str):
    return db.query(Produto).filter(Produto.nome == nome).first()

def atualizar(db: Session, produto: Produto, mudancas: dict):
    for campo, valor in mudancas.items():
        setattr(produto, campo, valor)
    db.commit()
    db.refresh(produto)
    return produto

def apagar(db: Session, produto: Produto):
    db.delete(produto)
    db.commit()