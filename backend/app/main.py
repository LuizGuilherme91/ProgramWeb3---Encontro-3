from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from .produtos import controller as produtos_controller
from .produtos.erros import ErroDeProduto, ProdutoNaoEncontrado

app = FastAPI(title="API do Meu Projeto", version="0.3.0")
app.include_router(produtos_controller.router)

@app.exception_handler(ErroDeProduto)
def traduzir_recusa(request: Request, erro: ErroDeProduto):
    """O unico lugar do sistema que transforma recusa em numero HTTP."""
    codigo = 404 if isinstance(erro, ProdutoNaoEncontrado) else 409
    return JSONResponse(status_code=codigo, content={"detail": str(erro)})