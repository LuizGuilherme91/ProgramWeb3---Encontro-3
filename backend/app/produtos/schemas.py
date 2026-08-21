from pydantic import BaseModel, Field

class ProdutoCriar(BaseModel):          # ENTRA no cadastro
    nome: str = Field(min_length=2)
    preco: float = Field(gt=0)
    em_estoque: bool = True

class ProdutoPublico(BaseModel):        # SAI na resposta
    id: int
    nome: str
    preco: float
    em_estoque: bool

class ProdutoAtualizar(BaseModel):      # ENTRA na edicao, tudo opcional
    nome: str | None = None
    preco: float | None = None
    em_estoque: bool | None = None