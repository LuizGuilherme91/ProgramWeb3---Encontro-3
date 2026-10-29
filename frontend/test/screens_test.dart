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
import 'package:frontend/screens/formulario_screen.dart';
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

// O acervo de mentira que guarda o que recebe para testar as rotas
http.Client acervoDeMentira() {
  final List<Map<String, dynamic>> acervo = [
    {'id': 1, 'nome': 'Cadeira', 'preco': 150.0, 'em_estoque': true, 'dono_id': 1},
    {'id': 2, 'nome': 'Mesa', 'preco': 450.0, 'em_estoque': false, 'dono_id': 1},
  ];
  return MockClient((pedido) async {
    pedidos++;
    final id = int.tryParse(pedido.url.pathSegments.last);
    if (pedido.method == 'POST' || pedido.method == 'PATCH') {
      final dados = jsonDecode(pedido.body);
      for (final produto in acervo) {
        if (produto['nome'] == dados['nome'] && produto['id'] != id) {
          return http.Response('{"detail": "Ja existe um produto chamado ${dados['nome']}"}', 409);
        }
      }
      if (pedido.method == 'POST') {
        final novo = {'id': 3, 'nome': dados['nome'], 'preco': dados['preco'], 'em_estoque': true, 'dono_id': 1};
        acervo.add(novo);
        return http.Response(jsonEncode(novo), 201);
      }
    }
    if (id == null) {
      return http.Response(jsonEncode(acervo), 200);
    }
    for (final produto in acervo) {
      if (produto['id'] == id) {
        if (pedido.method == 'DELETE') {
          if (produto['em_estoque'] == false) {
            return http.Response('{"detail": "Produto $id nao tem estoque"}', 409);
          }
          acervo.remove(produto);
          return http.Response('', 204);
        }
        if (pedido.method == 'PATCH') {
          produto.addAll(jsonDecode(pedido.body));
        }
        return http.Response(jsonEncode(produto), 200);
      }
    }
    return http.Response('{"detail": "Produto $id nao esta no seu acervo"}', 404);
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

Future<void> preencherEEntrar(WidgetTester tester, String senha) async {
  await tester.enterText(find.byType(TextField).at(0), 'ana@biblioteca.com');
  await tester.enterText(find.byType(TextField).at(1), senha);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
  await tester.pumpAndSettle();
}

Future<void> abrirOMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

Future<void> preencherECadastrar(WidgetTester tester, String email, String senha) async {
  await tester.tap(find.text('Criar uma conta'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).at(0), 'Bia');
  await tester.enterText(find.byType(TextField).at(1), email);
  await tester.enterText(find.byType(TextField).at(2), senha);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Cadastrar'));
  await tester.pumpAndSettle();
}

// Interage com o formulário
Future<void> preencherOFormulario(WidgetTester tester, String nome, String preco) async {
  await tester.tap(find.byTooltip('Novo produto'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), nome);
  await tester.enterText(find.byType(TextFormField).at(1), preco);
}

// Responde ao AlertDialog de exclusão
Future<void> excluirRespondendo(WidgetTester tester, String resposta) async {
  await tester.tap(find.text('Excluir'));
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(resposta)));
  await tester.pumpAndSettle();
}

Future<void> abrirOsProdutos(WidgetTester tester, http.Client produtos) async {
  final sessao = sessaoDeMentira(guardado: {'token': 'token-de-ana@biblioteca.com'});
  await sessao.restaurar();
  await tester.pumpWidget(appDeMentira(sessao, produtos: produtos));
  await tester.tap(find.text('Ver os produtos'));
  await tester.pumpAndSettle();
}

Future<String?> tokenGuardado() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

Matcher recusadoCom(String frase) {
  return throwsA(isA<ErroDeCadastro>().having((e) => e.mensagem, 'mensagem', frase));
}

void main() {
  testWidgets('a tela de login tem e-mail, senha e o botão Entrar', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
    expect(find.text('Criar uma conta'), findsOneWidget);
  });

  testWidgets('a tela de cadastro tem nome, e-mail e senha', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CadastroScreen()));
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.widgetWithText(ElevatedButton, 'Cadastrar'), findsOneWidget);
  });

  testWidgets('com a senha certa, a rota /inicio abre a tela inicial', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));
    await preencherEEntrar(tester, 'segredo123');
    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('com a senha errada, fica no login e mostra o erro', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));
    await preencherEEntrar(tester, 'senha-errada');
    expect(find.text('E-mail ou senha incorretos'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('o link Criar uma conta abre o cadastro pelo nome da rota', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));
    await tester.tap(find.text('Criar uma conta'));
    await tester.pumpAndSettle();
    expect(find.byType(CadastroScreen), findsOneWidget);
  });

  testWidgets('cadastrar pela tela cria a conta e abre a tela inicial', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));
    await preencherECadastrar(tester, 'bia@biblioteca.com', 'segredo456');
    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('Olá, Bia!'), findsOneWidget);
    expect(find.byType(CadastroScreen), findsNothing);
  });

  testWidgets('e-mail repetido: a tela mostra o erro e fica no cadastro', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));
    await preencherECadastrar(tester, 'ana@biblioteca.com', 'segredo456');
    expect(find.text('Já existe uma conta com este e-mail'), findsOneWidget);
    expect(find.byType(CadastroScreen), findsOneWidget);
    expect(find.byType(InicioScreen), findsNothing);
  });

  testWidgets('o link Já tenho conta leva ao login', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));
    await tester.tap(find.text('Criar uma conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Já tenho conta'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(CadastroScreen), findsNothing);
  });

  testWidgets('o guarda: sem sessão, a rota /inicio mostra o login', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));
    Navigator.of(tester.element(find.byType(LoginScreen))).pushNamed(AppRoutes.inicio);
    await tester.pumpAndSettle();
    expect(find.byType(InicioScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('o menu mostra o nome sem receber nada pelo construtor', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));
    await preencherEEntrar(tester, 'segredo123');
    await abrirOMenu(tester);
    final menu = find.byType(Drawer);
    expect(find.descendant(of: menu, matching: find.text('Ana')), findsOneWidget);
    expect(find.descendant(of: menu, matching: find.text('ana@biblioteca.com')), findsOneWidget);
    await tester.tap(find.descendant(of: menu, matching: find.text('Perfil')));
    await tester.pumpAndSettle();
    expect(find.byType(PerfilScreen), findsOneWidget);
  });

  testWidgets('sair volta ao login, limpa a pilha e apaga a sessão', (tester) async {
    final sessao = sessaoDeMentira();
    await tester.pumpWidget(appDeMentira(sessao));
    await preencherEEntrar(tester, 'segredo123');
    await tester.tap(find.text('Ver os produtos'));
    await tester.pumpAndSettle();
    expect(find.byType(ProdutosScreen), findsOneWidget);
    expect(await tokenGuardado(), 'token-de-ana@biblioteca.com');

    await abrirOMenu(tester);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ProdutosScreen), findsNothing);
    expect(Navigator.of(tester.element(find.byType(LoginScreen))).canPop(), isFalse);
    expect(sessao.logado, isFalse);
    expect(await tokenGuardado(), isNull);
  });

  testWidgets('com a sessão restaurada, o app abre direto na tela inicial', (tester) async {
    final sessao = sessaoDeMentira(guardado: {'token': 'token-de-ana@biblioteca.com'});
    await sessao.restaurar();
    await tester.pumpWidget(appDeMentira(sessao));
    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('o watch redesenha a tela quando o service avisa', (tester) async {
    final sessao = sessaoDeMentira();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: sessao,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final nome = context.watch<SessaoService>().usuario?.nome;
              return Text(nome ?? 'ninguém');
            },
          ),
        ),
      ),
    );
    expect(find.text('ninguém'), findsOneWidget);
    await sessao.entrar('ana@biblioteca.com', 'segredo123');
    await tester.pump();
    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('a tela de produtos mostra a lista: um ListTile por produto', (tester) async {
    await abrirOsProdutos(tester, apiDeProdutos(200, doisProdutos));
    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('Cadeira'), findsOneWidget);
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

    noAr = true;
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tentar de novo'));
    await tester.pumpAndSettle();
    expect(find.text('Cadeira'), findsOneWidget);
  });

  testWidgets('enquanto a resposta não chega, a tela mostra o carregando', (tester) async {
    final resposta = Completer<http.Response>();
    final sessao = sessaoDeMentira(guardado: {'token': 'token-de-ana@biblioteca.com'});
    await sessao.restaurar();
    await tester.pumpWidget(
      appDeMentira(sessao, produtos: MockClient((pedido) => resposta.future)),
    );
    await tester.tap(find.text('Ver os produtos'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    resposta.complete(http.Response(jsonEncode(doisProdutos), 200));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('tocar num produto abre o detalhe, que busca na API pelo id', (tester) async {
    await abrirOsProdutos(tester, apiDeProdutos(200, doisProdutos));
    pedidos = 0;
    await tester.tap(find.text('Mesa'));
    await tester.pumpAndSettle();
    expect(find.byType(ProdutoScreen), findsOneWidget);
    expect(find.text('R\$ 450.00'), findsOneWidget);
    expect(pedidos, 1);
  });

  testWidgets('o detalhe de um produto que não existe mais mostra o erro da API', (tester) async {
    await abrirOsProdutos(tester, apiDeProdutos(200, doisProdutos));
    Navigator.of(tester.element(find.byType(ProdutosScreen))).pushNamed(AppRoutes.produto, arguments: 99);
    await tester.pumpAndSettle();
    expect(find.text('Produto 99 nao esta no seu acervo'), findsOneWidget);
  });

  testWidgets('sem o produto na rota (o F5 no detalhe), a tela mostra a lista', (tester) async {
    await abrirOsProdutos(tester, apiDeProdutos(200, doisProdutos));
    Navigator.of(tester.element(find.byType(ProdutosScreen))).pushNamed(AppRoutes.produto);
    await tester.pumpAndSettle();
    expect(find.byType(ProdutoScreen), findsOneWidget);
  });

  // Novos testes para o formulário e modificações de acervo
  testWidgets('o + abre o formulário vazio, e salvar põe o produto novo na lista', (tester) async {
    await abrirOsProdutos(tester, acervoDeMentira());
    await preencherOFormulario(tester, 'Monitor', '800');
    expect(find.text('Novo produto'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.byType(FormularioScreen), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.text('Monitor'), findsOneWidget);
  });

  testWidgets('o validator segura o formulário: com campo errado, nada vai para a API', (tester) async {
    await abrirOsProdutos(tester, acervoDeMentira());
    await preencherOFormulario(tester, '', '');
    pedidos = 0;
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(find.text('Informe o nome do produto'), findsOneWidget);
    expect(find.text('Informe o preço, apenas com números e ponto (ex: 150.50)'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Monitor');
    await tester.enterText(find.byType(TextFormField).at(1), 'oitocentos');
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(find.text('Informe o nome do produto'), findsNothing);
    expect(find.text('Informe o preço, apenas com números e ponto (ex: 150.50)'), findsOneWidget);
    expect(pedidos, 0);
  });

  testWidgets('título repetido: a API recusa (409), e o formulário mostra a frase', (tester) async {
    await abrirOsProdutos(tester, acervoDeMentira());
    await preencherOFormulario(tester, 'Cadeira', '150');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Ja existe um produto chamado Cadeira'), findsOneWidget);
    expect(find.byType(FormularioScreen), findsOneWidget);
  });

  testWidgets('editar: o formulário vem preenchido, e salvar volta para a lista atualizada', (tester) async {
    await abrirOsProdutos(tester, acervoDeMentira());
    await tester.tap(find.text('Cadeira'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar produto'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Cadeira'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '150.0'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '200');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.byType(FormularioScreen), findsNothing);
    expect(find.byType(ProdutoScreen), findsNothing);
    expect(find.text('R\$ 200.00'), findsOneWidget);
  });

  testWidgets('excluir pergunta antes: Cancelar deixa o produto; Excluir o tira da lista', (tester) async {
    await abrirOsProdutos(tester, acervoDeMentira());
    await tester.tap(find.text('Cadeira'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir Cadeira?'), findsOneWidget);
    
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(ProdutoScreen), findsOneWidget);

    await excluirRespondendo(tester, 'Excluir');
    expect(find.byType(ProdutoScreen), findsNothing);
    expect(find.text('Cadeira'), findsNothing);
    expect(find.byType(ListTile), findsOneWidget); // sobrou só a mesa
  });

  testWidgets('depois de um F5 no formulário, ele mostra a lista', (tester) async {
    await abrirOsProdutos(tester, acervoDeMentira());
    Navigator.of(tester.element(find.byType(ProdutosScreen))).pushNamedAndRemoveUntil(
      AppRoutes.formulario,
      (rota) => false,
    );
    await tester.pumpAndSettle();
    expect(find.byType(FormularioScreen), findsOneWidget);
    expect(find.text('Novo produto'), findsNothing);
    expect(find.text('Cadeira'), findsOneWidget);
  });

  // Testes do service (sem tela)
  test('o service recusa campos vazios sem nem chamar a API', () async {
    final sessao = sessaoDeMentira();
    pedidos = 0;
    await expectLater(sessao.entrar('', ''), throwsA(isA<ErroDeLogin>()));
    expect(pedidos, 0);
  });

  test('entrar e sair mudam a sessão e avisam quem está de olho', () async {
    final sessao = sessaoDeMentira();
    var avisos = 0;
    sessao.addListener(() => avisos++);
    await sessao.entrar('ana@biblioteca.com', 'segredo123');
    expect(sessao.token, 'token-de-ana@biblioteca.com');
    await sessao.sair();
    expect(sessao.logado, isFalse);
    expect(avisos, 2);
  });

  test('o repositório manda o token no cabeçalho e devolve objetos', () async {
    String? cabecalho;
    final cliente = MockClient((pedido) async {
      cabecalho = pedido.headers['Authorization'];
      return http.Response(jsonEncode(doisProdutos), 200);
    });
    final produtos = await ProdutoRepository(cliente: cliente).listar('tk-123');
    expect(cabecalho, 'Bearer tk-123');
    expect(produtos, hasLength(2));
  });

  test('o repositório busca um produto só pelo id: GET /produtos/2', () async {
    String? caminho;
    final cliente = MockClient((pedido) async {
      caminho = pedido.url.path;
      return http.Response(jsonEncode(doisProdutos.last), 200);
    });
    final produto = await ProdutoRepository(cliente: cliente).buscar('tk-123', 2);
    expect(caminho, '/produtos/2');
    expect(produto.nome, 'Mesa');
  });

  test('o repositório cria com POST e token no cabeçalho', () async {
    late http.Request enviado;
    final cliente = MockClient((pedido) async {
      enviado = pedido;
      return http.Response(
        jsonEncode({'id': 3, 'nome': 'Monitor', 'preco': 800, 'em_estoque': true, 'dono_id': 1}), 201,
      );
    });
    final produto = await ProdutoRepository(cliente: cliente).criar('tk-123', 'Monitor', 800);
    expect(enviado.method, 'POST');
    expect(enviado.headers['Authorization'], 'Bearer tk-123');
    expect(jsonDecode(enviado.body), {'nome': 'Monitor', 'preco': 800});
    expect(produto.id, 3);
  });

  test('o repositório edita com PATCH e exclui com DELETE', () async {
    final feitos = <String>[];
    final cliente = MockClient((pedido) async {
      feitos.add('${pedido.method} ${pedido.url.path}');
      if (pedido.method == 'DELETE') return http.Response('', 204);
      return http.Response(jsonEncode(doisProdutos.first), 200);
    });
    final repositorio = ProdutoRepository(cliente: cliente);
    await repositorio.atualizar('tk-123', 1, 'Cadeira', 200);
    await repositorio.excluir('tk-123', 1);
    expect(feitos, ['PATCH /produtos/1', 'DELETE /produtos/1']);
  });

  test('o 422 da API vira a frase da tela', () async {
    final sessao = sessaoDeMentira();
    await sessao.entrar('ana@biblioteca.com', 'segredo123');
    final recusa = MockClient((pedido) async {
      return http.Response(
        jsonEncode({'detail': [{'loc': ['body', 'preco'], 'msg': 'Value error, preco nao pode ser negativo'}]}), 422
      );
    });
    final servico = ProdutoService(ProdutoRepository(cliente: recusa), sessao);
    await expectLater(
      servico.criar('Mesa', -10),
      throwsA(isA<ErroDeProdutos>().having((e) => '$e', 'texto', 'preco: preco nao pode ser negativo')),
    );
  });
}