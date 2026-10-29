from . import repository
from .erros import (
    CampoNaoEditavel,
    NomeJaCadastrado,
    ProdutoEmEstoque,
    ProdutoNaoEncontrado,
)

RN02_PROIBIDO = "em_estoque"


def listar(db, usuario, nome=None, em_estoque=None):
    return repository.listar(db, usuario.id, nome, em_estoque)


def buscar(db, usuario, produto_id):
    produto = repository.buscar(db, produto_id)
    if produto is None or produto.dono_id != usuario.id:
        raise ProdutoNaoEncontrado(f"Produto {produto_id} nao esta no seu catalogo")
    return produto


def criar(db, usuario, dados):
    if repository.buscar_por_nome(db, usuario.id, dados["nome"]):
        raise NomeJaCadastrado(f"Ja existe um produto chamado {dados['nome']}")
    # O dono vem de quem esta logado
    return repository.criar(db, {**dados, "dono_id": usuario.id})


def atualizar(db, usuario, produto_id, mudancas):
    produto = buscar(db, usuario, produto_id)

    novo_nome = mudancas.get("nome")
    if novo_nome and novo_nome != produto.nome:
        if repository.buscar_por_nome(db, usuario.id, novo_nome):
            raise NomeJaCadastrado(f"Ja existe um produto chamado {novo_nome}")

    if RN02_PROIBIDO in mudancas:
        raise CampoNaoEditavel("em_estoque nao se edita pelo catalogo")

    return repository.atualizar(db, produto, mudancas)


def apagar(db, usuario, produto_id):
    produto = buscar(db, usuario, produto_id)
    if produto.em_estoque:
        raise ProdutoEmEstoque(f"Produto {produto_id} ainda tem estoque")
    repository.apagar(db, produto)