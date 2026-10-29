import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/produto.dart';
import '../routes.dart';
import '../services/produto_service.dart';
import '../widgets/app_drawer.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  late Future<List<Produto>> produtos;

  @override
  void initState() {
    super.initState();
    produtos = context.read<ProdutoService>().listar();
  }

  // Pede a lista de novo: volta de uma tela que mudou o acervo (fechou com true).
  void pedirDeNovo() {
    setState(() {
      produtos = context.read<ProdutoService>().listar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<Produto>>(
        future: produtos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 56),
                  const SizedBox(height: 16),
                  const Text('Não consegui carregar os produtos'),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: pedirDeNovo,
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            );
          }
          final lista = snapshot.data!;
          if (lista.isEmpty) {
            return const Center(child: Text('Nenhum produto ainda.'));
          }
          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final produto = lista[i];
              return ListTile(
                leading: const Icon(Icons.inventory),
                title: Text(produto.nome),
                subtitle: Text('R\$ ${produto.preco.toStringAsFixed(2)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final mudou = await Navigator.pushNamed(context, AppRoutes.produto, arguments: produto.id);
                  if (mudou == true) {
                    pedirDeNovo();
                  }
                },
              );
            },
          );
        },
      ),
      // O + abre o formulário vazio. Se voltar true (salvou), recarrega a lista.
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo produto',
        onPressed: () async {
          final salvou = await Navigator.pushNamed(context, AppRoutes.formulario);
          if (salvou == true) {
            pedirDeNovo();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}