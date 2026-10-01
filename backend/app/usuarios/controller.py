# backend/app/usuarios/controller.py
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ..database import get_db
from ..seguranca import criar_token_acesso, get_current_user, obter_hash_senha, verificar_senha
from .models import Usuario

router = APIRouter(prefix="/usuarios", tags=["Usuários"])

class UsuarioCriar(BaseModel):
    nome: str
    email: str
    senha: str

class UsuarioPublico(BaseModel):
    id: int
    nome: str
    email: str

@router.post("/", response_model=UsuarioPublico, status_code=201)
def criar_usuario(usuario: UsuarioCriar, db: Session = Depends(get_db)):
    if db.query(Usuario).filter(Usuario.email == usuario.email).first():
        raise HTTPException(status_code=400, detail="E-mail já cadastrado")
    
    novo_usuario = Usuario(
        nome=usuario.nome,
        email=usuario.email,
        senha_hash=obter_hash_senha(usuario.senha)
    )
    db.add(novo_usuario)
    db.commit()
    db.refresh(novo_usuario)
    return novo_usuario

@router.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    usuario = db.query(Usuario).filter(Usuario.email == form_data.username).first()
    if not usuario or not verificar_senha(form_data.password, usuario.senha_hash):
        raise HTTPException(status_code=401, detail="E-mail ou senha incorretos")
    
    token = criar_token_acesso(dados={"sub": usuario.email})
    return {"access_token": token, "token_type": "bearer"}

@router.get("/eu", response_model=UsuarioPublico)
def quem_sou_eu(usuario_atual: Usuario = Depends(get_current_user)):
    return usuario_atual