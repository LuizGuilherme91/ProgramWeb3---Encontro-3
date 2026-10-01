import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const ProdutosApp());
}

class ProdutosApp extends StatelessWidget {
  const ProdutosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão de Produtos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const LoginScreen(),
    );
  }
}