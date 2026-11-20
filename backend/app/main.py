import os

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .produtos import controller as produtos_controller
from .produtos.erros import ErroDeProduto, ProdutoNaoEncontrado
from .usuarios import controller as usuarios_controller

app = FastAPI(title="API de Gestão de Produtos", version="0.3.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[os.getenv("ENDERECO_DO_APP", "")],
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(usuarios_controller.router)
app.include_router(produtos_controller.router)


@app.exception_handler(ErroDeProduto)
def traduzir_recusa(request: Request, erro: ErroDeProduto):
    codigo = 404 if isinstance(erro, ProdutoNaoEncontrado) else 409
    return JSONResponse(status_code=codigo, content={"detail": str(erro)})