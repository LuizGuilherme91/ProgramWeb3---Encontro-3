class ErroDeProduto(Exception):
    """Qualquer recusa do catalogo. Quem traduz para HTTP e o controller."""


class ProdutoNaoEncontrado(ErroDeProduto):
    """Pediram um produto que nao esta no catalogo."""


class NomeJaCadastrado(ErroDeProduto):
    """Ja existe um produto com esse nome no catalogo."""


class CampoNaoEditavel(ErroDeProduto):
    """Tentaram editar pelo catalogo um campo que nao e do catalogo."""


class ProdutoEmEstoque(ErroDeProduto):
    """Nao se apaga produto que ainda consta em estoque."""