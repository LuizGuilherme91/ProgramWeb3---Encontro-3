# backend/app/seguranca.py
import jwt
from datetime import datetime, timedelta, timezone
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from .database import get_db
from .usuarios.models import Usuario

# Configurações do Token
SECRET_KEY = "chave_secreta_do_trabalho_da_faculdade"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Aponta para a rota de login que vamos criar no passo 3
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="usuarios/login")

def verificar_senha(senha_pura, senha_hash):
    return pwd_context.verify(senha_pura, senha_hash)

def obter_hash_senha(senha):
    return pwd_context.hash(senha)

def criar_token_acesso(dados: dict):
    copia = dados.copy()
    expira = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    copia.update({"exp": expira})
    return jwt.encode(copia, SECRET_KEY, algorithm=ALGORITHM)

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    excecao = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Credenciais inválidas",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str | None = payload.get("sub")
        if email is None:
            raise excecao
    except jwt.InvalidTokenError:
        raise excecao
    
    usuario = db.query(Usuario).filter(Usuario.email == email).first()
    if usuario is None:
        raise excecao
    return usuario