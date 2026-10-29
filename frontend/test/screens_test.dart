import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';
import 'package:frontend/models/produto.dart';
import 'package:frontend/repositories/produto_repository.dart';
import 'package:frontend/repositories/usuario_repository.dart';
import 'package:frontend/routes.dart';
import 'package:frontend/screens/cadastro_screen.dart';
import 'package:frontend/screens/inicio_screen.dart';
import 'package:frontend/screens/produto_screen.dart';
import 'package:frontend/screens/produtos_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/perfil_screen.dart';
import 'package:frontend/services/produto_service.dart';
import 'package:frontend/services/sessao_service.dart';

int pedidos = 0;

SessaoService sessaoDeMentira({Map<String, Object> guardado = const {}}) {
  SharedPreferences.setMockInitialValues(guardado);
  final contas = {
    'ana@biblioteca.com': {'nome': 'Ana', 'senha': 'segredo123'},
  };
  final cliente = MockClient((pedido) async {
    pedidos++;
    if (pedido.url.path == '/usuarios/' && pedido.method == 'POST') {
      final dados = jsonDecode(pedido.body);
      if (contas.containsKey(dados['email'])) {
        return http.Response('{"detail": "Ja existe uma conta com o e-mail ${dados['email']}"}', 409);
      }
      if (dados['senha'].length < 6) {
        return http.Response(
          jsonEncode({'detail': [{'loc': ['body', 'senha'], 'msg': 'String should have at least 6 characters'}]}), 422
        );
      }
      contas[dados['email']] = {'nome': dados['nome'], 'senha': dados['senha']};
      return http.Response(jsonEncode({'id': 2, 'nome': dados['nome'], 'email': dados['email']}), 201);
    }
    if (pedido.url.path == '/usuarios/login') {
      final email = pedido.bodyFields['username'];
      if (contas[email]?['senha'] == pedido.bodyFields['password']) {
        return http.Response(jsonEncode({'access_token': 'token-de-$email', 'token_type': 'bearer'}), 200);
      }
      return http.Response('{"detail": "E-mail ou senha incorretos"}', 401);
    }
    if (pedido.url.path == '/usuarios/eu') {
      final email = (pedido.headers['Authorization'] ?? '').replaceFirst('Bearer token-de-', '');
      if (contas.containsKey(email)) {
        return http.Response(jsonEncode({'id': 1, 'nome': contas[email]!['nome'], 'email': email}), 200);
      }
    }
    return http.Response('{"detail": "Token invalido ou vencido"}', 401);
  });
  return SessaoService(UsuarioRepository(cliente: cliente));
}

const doisProdutos = [
  {'id': 1, 'nome': 'Cadeira', 'preco': 150.0, 'em_estoque': true, 'dono_id': 1},
  {'id': 2, 'nome': 'Mesa', 'preco': 450.0, 'em_estoque': false, 'dono_id': 1},
];

http.Client apiDeProdutos(int status, Object corpo) {
  return MockClient((pedido) async {
    pedidos++;
    if (pedido.headers['Authorization'] == null) {
      return http.Response('{"detail": "Not authenticated"}', 401);
    }
    final id = pedido.url.pathSegments.last;
    if (id.isNotEmpty) {
      for (final produto in doisProdutos) {
        if ('${produto['id']}' == id) {
          return http.Response(jsonEncode(produto), 200);
        }
      }
      return http.Response('{"detail": "Produto $id nao esta no seu acervo"}', 404);
    }
    return http.Response(jsonEncode(corpo), status);
  });
}

Widget appDeMentira(SessaoService sessao, {http.Client? produtos}) {
  final repositorio = ProdutoRepository(cliente: produtos ?? apiDeProdutos(200, []));
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: sessao),
      Provider.value(value: ProdutoService(repositorio, sessao)),
    ],
    child: const ProdutosApp(),
  );
}

Future<void> abrirOsProdutos(WidgetTester tester, http.Client produtos) async {
  final sessao = sessaoDeMentira(guardado: {'token': 'token-de-ana@biblioteca.com'});
  await sessao.restaurar();
  await tester.pumpWidget(appDeMentira(sessao, produtos: produtos));
  await tester.tap(find.text('Ver os produtos'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a tela de produtos mostra a lista: um ListTile por produto', (tester) async {
    await abrirOsProdutos(tester, apiDeProdutos(200, doisProdutos));
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('Cadeira'), findsOneWidget);
    expect(find.text('R\$ 450.00'), findsOneWidget);
  });

  testWidgets('sem produto nenhum, a tela diz que a lista está vazia', (tester) async {
    await abrirOsProdutos(tester, apiDeProdutos(200, []));
    expect(find.text('Nenhum produto ainda.'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('com a API parada, o erro; o Tentar de novo pede outra vez', (tester) async {
    var noAr = false;
    final produtos = MockClient((pedido) async {
      if (!noAr) throw http.ClientException('Failed to fetch');
      return http.Response(jsonEncode(doisProdutos), 200);
    });
    await abrirOsProdutos(tester, produtos);
    expect(find.text('Não consegui carregar os produtos'), findsOneWidget);
    expect(find.text('Não consegui falar com a API. O uvicorn está rodando?'), findsOneWidget);

    noAr = true;
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('Cadeira'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsNothing);
  });

  testWidgets('enquanto a resposta não chega, a tela mostra o carregando', (tester) async {
    final resposta = Completer<http.Response>();
    final sessao = sessaoDeMentira(guardado: {'token': 'token-de-ana@biblioteca.com'});
    await sessao.restaurar();
    await tester.pumpWidget(appDeMentira(sessao, produtos: MockClient((pedido) => resposta.future)));
    await tester.tap(find.text('Ver os produtos'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    resposta.complete(http.Response(jsonEncode(doisProdutos), 200));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Cadeira'), findsOneWidget);
  });

  testWidgets('tocar num produto abre o detalhe, que busca o produto na API pelo id', (tester) async {
    await abrirOsProdutos(tester, apiDeProdutos(200, doisProdutos));
    pedidos = 0;

    await tester.tap(find.text('Mesa'));
    await tester.pumpAndSettle();

    expect(find.byType(ProdutoScreen), findsOneWidget);
    expect(find.text('R\$ 450.00'), findsOneWidget);
    expect(find.text('Esgotado'), findsOneWidget);
    expect(pedidos, 1);
  });

  testWidgets('o detalhe de um produto que não existe mais mostra o erro da API', (tester) async {
    await abrirOsProdutos(tester, apiDeProdutos(200, doisProdutos));

    Navigator.of(tester.element(find.byType(ProdutosScreen))).pushNamed(AppRoutes.produto, arguments: 99);
    await tester.pumpAndSettle();

    expect(find.text('Não consegui carregar o produto'), findsOneWidget);
    expect(find.text('Produto 99 nao esta no seu acervo'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  testWidgets('sem o produto na rota (o F5 no detalhe), a tela mostra a lista', (tester) async {
    await abrirOsProdutos(tester, apiDeProdutos(200, doisProdutos));

    Navigator.of(tester.element(find.byType(ProdutosScreen))).pushNamed(AppRoutes.produto);
    await tester.pumpAndSettle();

    expect(find.byType(ProdutoScreen), findsOneWidget);
    expect(find.text('Cadeira'), findsOneWidget);
  });

  test('o repositório manda o token no cabeçalho e devolve objetos Produto', () async {
    String? cabecalho;
    final cliente = MockClient((pedido) async {
      cabecalho = pedido.headers['Authorization'];
      return http.Response(jsonEncode(doisProdutos), 200);
    });

    final lista = await ProdutoRepository(cliente: cliente).listar('tk-123');

    expect(cabecalho, 'Bearer tk-123');
    expect(lista, hasLength(2));
    expect(lista.first, isA<Produto>());
    expect(lista.first.nome, 'Cadeira');
    expect(lista.last.emEstoque, isFalse);
  });

  test('o repositório busca um produto só pelo id, com o token: GET /produtos/2', () async {
    String? caminho;
    String? cabecalho;
    final cliente = MockClient((pedido) async {
      caminho = pedido.url.path;
      cabecalho = pedido.headers['Authorization'];
      return http.Response(jsonEncode(doisProdutos.last), 200);
    });

    final produto = await ProdutoRepository(cliente: cliente).buscar('tk-123', 2);

    expect(caminho, '/produtos/2');
    expect(cabecalho, 'Bearer tk-123');
    expect(produto.nome, 'Mesa');
  });

  test('o service dos produtos traduz a recusa: a frase da API vai para a tela', () async {
    final sessao = sessaoDeMentira();
    await sessao.entrar('ana@biblioteca.com', 'segredo123');
    final recusa = apiDeProdutos(401, {'detail': 'Token invalido ou vencido'});
    final servico = ProdutoService(ProdutoRepository(cliente: recusa), sessao);

    await expectLater(
      servico.listar(),
      throwsA(isA<ErroDeProdutos>().having((e) => '$e', 'texto', 'Token invalido ou vencido')),
    );
  });
}