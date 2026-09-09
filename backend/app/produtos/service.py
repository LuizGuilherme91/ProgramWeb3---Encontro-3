"""As regras do catalogo, e mais nada.

Este arquivo decide. Ele nao levanta erro de protocolo, nao monta consulta
e nao abre conexao: quem fala HTTP e o controller, quem fala SQL e o
repository.
"""
from . import repository
from .erros import (
    CampoNaoEditavel,
    NomeJaCadastrado,
    ProdutoEmEstoque,
    ProdutoNaoEncontrado,
)

RN02_PROIBIDO = "em_estoque"


def listar(db):
    return repository.listar(db)


def buscar(db, produto_id):
    produto = repository.buscar(db, produto_id)
    if produto is None:
        raise ProdutoNaoEncontrado(f"Produto {produto_id} nao esta no catalogo")
    return produto


def criar(db, dados):
    if repository.buscar_por_nome(db, dados["nome"]):
        raise NomeJaCadastrado(f"Ja existe um produto chamado {dados['nome']}")
    return repository.criar(db, dados)


def atualizar(db, produto_id, mudancas):
    produto = buscar(db, produto_id)

    novo_nome = mudancas.get("nome")
    if novo_nome and novo_nome != produto.nome:
        if repository.buscar_por_nome(db, novo_nome):
            raise NomeJaCadastrado(f"Ja existe um produto chamado {novo_nome}")

    if RN02_PROIBIDO in mudancas:
        raise CampoNaoEditavel("em_estoque nao se edita pelo catalogo")

    return repository.atualizar(db, produto, mudancas)


def apagar(db, produto_id):
    produto = buscar(db, produto_id)
    if produto.em_estoque:
        raise ProdutoEmEstoque(f"Produto {produto_id} ainda tem estoque")
    repository.apagar(db, produto)