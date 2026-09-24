from pydantic import BaseModel, ConfigDict, field_validator


def _nome_legivel(nome: str) -> str:
    # A mensagem e' para quem le a resposta 422: diz o que fazer, nao o que
    # o validador se chama.
    if len(nome.strip()) < 2:
        raise ValueError("o nome precisa ter pelo menos 2 caracteres")
    return nome.strip()


def _preco_valido(preco: float) -> float:
    if preco <= 0:
        raise ValueError("o preco precisa ser maior que zero")
    return preco


class ProdutoCriar(BaseModel):        # ENTRA no cadastro
    nome: str
    preco: float
    em_estoque: bool = True

    @field_validator("nome")
    @classmethod
    def nome_legivel(cls, v):
        return _nome_legivel(v)

    @field_validator("preco")
    @classmethod
    def preco_valido(cls, v):
        return _preco_valido(v)


class ProdutoPublico(BaseModel):      # SAI na resposta
    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    preco: float
    em_estoque: bool
    dono_id: int | None          # de quem e' -- None nos produtos de antes do dono


class ProdutoAtualizar(BaseModel):    # ENTRA na edicao, tudo opcional
    nome: str | None = None
    preco: float | None = None
    em_estoque: bool | None = None

    @field_validator("nome")
    @classmethod
    def nome_legivel(cls, v):
        return v if v is None else _nome_legivel(v)

    @field_validator("preco")
    @classmethod
    def preco_valido(cls, v):
        return v if v is None else _preco_valido(v)