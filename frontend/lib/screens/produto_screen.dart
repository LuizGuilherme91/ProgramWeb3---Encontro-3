import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/produto.dart';
import '../services/produto_service.dart';
import 'produtos_screen.dart';

// O detalhe de um produto. Chega só o id, e a tela pede o produto à API:
// o dado é o de agora, e não o de quando a lista carregou.
class ProdutoScreen extends StatefulWidget {
  const ProdutoScreen({super.key, this.id});

  // O id que a rota tirou dos arguments. Sem ele (um F5 aqui apaga os
  // arguments), a tela mostra a lista.
  final int? id;

  @override
  State<ProdutoScreen> createState() => _ProdutoScreenState();
}

class _ProdutoScreenState extends State<ProdutoScreen> {
  // O pedido do produto nasce uma vez, no initState.
  late Future<Produto> pedido;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      pedido = context.read<ProdutoService>().buscar(widget.id!);
    }
  }

  void tentarDeNovo() {
    setState(() {
      pedido = context.read<ProdutoService>().buscar(widget.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id == null) {
      return const ProdutosScreen();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do Produto')),
      body: FutureBuilder<Produto>(
        future: pedido,
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
                  const Text('Não consegui carregar o produto'),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: tentarDeNovo,
                    child: const Text('Tentar de novo'),
                  ),
                ],
              ),
            );
          }
          final produto = snapshot.data!;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text('Nome'),
                subtitle: Text(produto.nome),
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Preço'),
                subtitle: Text('R\$ ${produto.preco.toStringAsFixed(2)}'),
              ),
              ListTile(
                leading: Icon(produto.emEstoque ? Icons.check_circle : Icons.cancel),
                title: const Text('Situação'),
                subtitle: Text(produto.emEstoque ? 'Em Estoque' : 'Esgotado'),
              ),
            ],
          );
        },
      ),
    );
  }
}