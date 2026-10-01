import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/screens/cadastro_screen.dart';
import 'package:frontend/screens/login_screen.dart';

void main() {
  testWidgets('A tela de login tem e-mail, senha e o botão Entrar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
    expect(find.text('Criar uma conta'), findsOneWidget);
  });

  testWidgets('A tela de cadastro tem nome, e-mail e senha', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CadastroScreen()));

    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.widgetWithText(ElevatedButton, 'Cadastrar'), findsOneWidget);
  });
}