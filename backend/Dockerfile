# A receita da API. Quem constrói a imagem é o serviço de nuvem: nada disto
# precisa de Docker na sua máquina.

# Comece de uma base pronta: um Python já instalado (3.14 para bater com o seu pyproject.toml).
FROM python:3.14-slim

# A pasta de trabalho, dentro do contêiner.
WORKDIR /codigo

# Instale os pacotes do projeto, sem os de desenvolvimento (o pytest fica fora).
COPY pyproject.toml poetry.lock* ./
RUN pip install poetry && poetry config virtualenvs.create false && poetry install --only main --no-interaction --no-root

# Copie o código. O .dockerignore diz o que não entra.
COPY . .

# Ao ligar: crie ou atualize as tabelas e suba a API. O serviço de nuvem diz a
# porta na variável PORT; sem ela, a 8000.
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]