import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:frontend/repositories/produto_repository.dart';
import 'package:frontend/repositories/usuario_repository.dart';
import 'package:frontend/screens/produtos_screen.dart';
import 'package:frontend/services/produto_service.dart';
import 'package:frontend/services/sessao_service.dart';

// A lista pede os produtos à API. Aqui, quem responde é uma API de mentira: para
// qualquer pedido, ela devolve o texto que o teste escolheu.
Future<void> abrirALista(WidgetTester tester, String respostaDaApi) async {
  final api = MockClient((pedido) async => http.Response(respostaDaApi, 200));
  final sessao = SessaoService(UsuarioRepository());
  sessao.token = 'um-token';
  final produtos = ProdutoService(ProdutoRepository(cliente: api), sessao);

  await tester.pumpWidget(
    Provider.value(
      value: produtos,
      child: const MaterialApp(home: ProdutosScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a lista mostra o produto que a API devolveu', (tester) async {
    await abrirALista(
      tester,
      '[{"id": 1, "nome": "Cadeira Gamer", "preco": 850.0, "em_estoque": true, "dono_id": 1}]',
    );

    expect(find.text('Cadeira Gamer'), findsOneWidget);
    expect(find.text('Nenhum produto ainda.'), findsNothing);
  });

  testWidgets('sem produto nenhum, a lista avisa que está vazia', (
    tester,
  ) async {
    await abrirALista(tester, '[]');

    expect(find.text('Nenhum produto ainda.'), findsOneWidget);
  });
}
