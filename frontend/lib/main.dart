import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repositories/produto_repository.dart';
import 'repositories/token_repository.dart';
import 'repositories/usuario_repository.dart';
import 'routes.dart';
import 'screens/cadastro_screen.dart';
import 'screens/inicio_screen.dart';
import 'screens/produto_screen.dart';
import 'screens/produtos_screen.dart';
import 'screens/login_screen.dart';
import 'screens/perfil_screen.dart';
import 'services/produto_service.dart';
import 'services/sessao_service.dart';
import 'widgets/rota_protegida.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessao = SessaoService(UsuarioRepository(), tokens: TokenRepository());
  await sessao.restaurar();
  
  // O service dos produtos pega o token na sessão: nasce com ela na mão.
  final produtos = ProdutoService(ProdutoRepository(), sessao);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sessao),
        Provider.value(value: produtos),
      ],
      child: const ProdutosApp(),
    ),
  );
}

class ProdutosApp extends StatelessWidget {
  const ProdutosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão de Produtos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      initialRoute: AppRoutes.inicio,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.cadastro: (context) => const CadastroScreen(),
        AppRoutes.inicio: (context) => const RotaProtegida(tela: InicioScreen()),
        AppRoutes.produtos: (context) => const RotaProtegida(tela: ProdutosScreen()),
        // O detalhe: a rota entrega à tela o id que veio nos arguments.
        AppRoutes.produto: (context) => RotaProtegida(
          tela: ProdutoScreen(id: ModalRoute.of(context)!.settings.arguments as int?),
        ),
        AppRoutes.perfil: (context) => const RotaProtegida(tela: PerfilScreen()),
      },
    );
  }
}