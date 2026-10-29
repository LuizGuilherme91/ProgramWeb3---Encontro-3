from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
# Importando a seguranca (ajuste o caminho se o seu arquivo de seguranca tiver outro nome)
from ..seguranca import get_current_user
from ..usuarios.models import Usuario

from . import service
from .schemas import ProdutoAtualizar, ProdutoCriar, ProdutoPublico

# A porta continua no router: nenhuma rota roda sem token. A novidade e' que
# cada rota agora tambem RECEBE o usuario -- porque precisa saber quem e'.
router = APIRouter(
    prefix="/produtos",
    tags=["Produtos"],
    dependencies=[Depends(get_current_user)],
)

@router.get("/", response_model=list[ProdutoPublico])
def listar(
    nome: str | None = None,          # ?nome=cadeira -- parametro de consulta
    em_estoque: bool | None = None,   # ?em_estoque=true
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.listar(db, usuario, nome, em_estoque)


@router.post("/", response_model=ProdutoPublico, status_code=201)
def criar(
    dados: ProdutoCriar,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.criar(db, usuario, dados.model_dump())


@router.get("/{produto_id}", response_model=ProdutoPublico)
def buscar(
    produto_id: int,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.buscar(db, usuario, produto_id)


@router.patch("/{produto_id}", response_model=ProdutoPublico)
def atualizar(
    produto_id: int,
    dados: ProdutoAtualizar,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return service.atualizar(db, usuario, produto_id, dados.model_dump(exclude_unset=True))


@router.delete("/{produto_id}", status_code=204)
def apagar(
    produto_id: int,
    usuario: Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    service.apagar(db, usuario, produto_id)