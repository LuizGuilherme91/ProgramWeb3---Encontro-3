"""Cada teste faz pedidos de verdade à API, sem uvicorn e sem o seu banco."""

PRODUTO = {"nome": "Cadeira Gamer", "preco": 850.0}


# Cria a conta, faz o login e devolve o cabeçalho com o token.
def entrar(cliente, email):
    cliente.post("/usuarios/", json={"nome": "Teste", "email": email, "senha": "segredo123"})
    dados = {"username": email, "password": "segredo123"}
    resposta = cliente.post("/usuarios/login", data=dados)
    return {"Authorization": "Bearer " + resposta.json()["access_token"]}


def test_criar_um_produto_devolve_201_com_o_nome(cliente):
    ana = entrar(cliente, "ana@ifg.edu.br")

    resposta = cliente.post("/produtos/", json=PRODUTO, headers=ana)

    assert resposta.status_code == 201
    assert resposta.json()["nome"] == "Cadeira Gamer"


def test_sem_token_a_api_recusa(cliente):
    resposta = cliente.get("/produtos/")

    assert resposta.status_code == 401


def test_o_bruno_nao_ve_o_produto_da_ana(cliente):
    ana = entrar(cliente, "ana@ifg.edu.br")
    bruno = entrar(cliente, "bruno@ifg.edu.br")
    cliente.post("/produtos/", json=PRODUTO, headers=ana)

    lista_da_ana = cliente.get("/produtos/", headers=ana).json()
    lista_do_bruno = cliente.get("/produtos/", headers=bruno).json()

    assert len(lista_da_ana) == 1
    assert lista_do_bruno == []


def test_editar_muda_o_nome(cliente):
    ana = entrar(cliente, "ana@ifg.edu.br")
    produto = cliente.post("/produtos/", json=PRODUTO, headers=ana).json()

    mudanca = {"nome": "Mesa Escritório"}
    resposta = cliente.patch(f"/produtos/{produto['id']}", json=mudanca, headers=ana)

    assert resposta.status_code == 200
    assert resposta.json()["nome"] == "Mesa Escritório"


def test_excluir_tira_o_produto_da_lista(cliente):
    ana = entrar(cliente, "ana@ifg.edu.br")
    produto = cliente.post(
        "/produtos/",
        json={**PRODUTO, "em_estoque": False},
        headers=ana,
    ).json()

    resposta = cliente.delete(f"/produtos/{produto['id']}", headers=ana)

    assert resposta.status_code == 204
    assert cliente.get("/produtos/", headers=ana).json() == []


def test_produto_que_nao_existe_devolve_404(cliente):
    ana = entrar(cliente, "ana@ifg.edu.br")

    resposta = cliente.get("/produtos/999", headers=ana)

    assert resposta.status_code == 404


def test_o_mesmo_nome_duas_vezes_devolve_409(cliente):
    ana = entrar(cliente, "ana@ifg.edu.br")
    cliente.post("/produtos/", json=PRODUTO, headers=ana)

    resposta = cliente.post("/produtos/", json=PRODUTO, headers=ana)

    assert resposta.status_code == 409


def test_a_busca_devolve_so_o_que_combina(cliente):
    ana = entrar(cliente, "ana@ifg.edu.br")
    cliente.post("/produtos/", json=PRODUTO, headers=ana)
    cliente.post("/produtos/", json={"nome": "Mesa Escritório", "preco": 450.5}, headers=ana)

    resposta = cliente.get("/produtos/", params={"nome": "cadeira"}, headers=ana)

    assert len(resposta.json()) == 1
    assert resposta.json()[0]["nome"] == "Cadeira Gamer"


def test_senha_errada_devolve_401(cliente):
    entrar(cliente, "ana@ifg.edu.br")
    dados = {"username": "ana@ifg.edu.br", "password": "senha-errada"}

    resposta = cliente.post("/usuarios/login", data=dados)

    assert resposta.status_code == 401