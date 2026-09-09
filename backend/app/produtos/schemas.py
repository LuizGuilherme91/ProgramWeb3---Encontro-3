from pydantic import BaseModel, ConfigDict, Field

class ProdutoCriar(BaseModel):            
    nome: str = Field(min_length=2)
    preco: float = Field(gt=0)
    em_estoque: bool = True

class ProdutoPublico(BaseModel):          
    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    preco: float
    em_estoque: bool

class ProdutoAtualizar(BaseModel):        
    nome: str | None = None
    preco: float | None = None
    em_estoque: bool | None = None