# frontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


As telas têm nome (`lib/routes.dart`) e o `main.dart` liga cada nome à tela. As telas de dentro do app passam pelo `RotaProtegida`: sem sessão, mostram o login.

A sessão (`SessaoService`) fica no topo do app, num `ChangeNotifierProvider`, e as telas a leem com `context.read` e `context.watch`: nenhuma recebe a sessão pelo construtor. O token vive só na memória: recarregar a página (F5) sai do app.

O cadastro chama `POST /usuarios/` pelas mesmas camadas do login e já entra com a conta nova. Quando a API recusa (e-mail repetido, campo inválido), a frase aparece na tela.

O token fica no aparelho (`shared_preferences`, que no navegador é o `localStorage`), num repositório próprio, o `TokenRepository`. O `main` o restaura antes de abrir o app: se a API ainda o aceita, o F5 não derruba a sessão. O Sair apaga o token.

A tela de produtos chama `GET /produtos/` pelas camadas do app (tela, `ProdutoService`, `ProdutoRepository`), com o token no cabeçalho, e mostra só os produtos de quem está logado. Ela tem quatro estados: carregando, erro (com Tentar de novo), lista vazia e a lista.

Tocar num produto abre o detalhe pela rota `/produto`, com o id nos `arguments`: o detalhe busca o produto na API (`GET /produtos/{id}`), para mostrar o dado de agora.