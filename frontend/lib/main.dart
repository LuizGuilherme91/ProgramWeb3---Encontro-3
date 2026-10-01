import 'package:flutter/material.dart';

import 'repositories/usuario_repository.dart';
import 'screens/login_screen.dart';
import 'services/sessao_service.dart';

void main() {
  final sessao = SessaoService(UsuarioRepository());
  runApp(ProdutosApp(sessao: sessao));
}

class ProdutosApp extends StatelessWidget {
  const ProdutosApp({super.key, required this.sessao});

  final SessaoService sessao;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão de Produtos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: LoginScreen(sessao: sessao),
    );
  }
}