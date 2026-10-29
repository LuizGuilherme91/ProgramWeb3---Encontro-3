import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/produto.dart';
import '../routes.dart';
import '../services/produto_service.dart';
import 'produtos_screen.dart';

class ProdutoScreen extends StatefulWidget {
  const ProdutoScreen({super.key, this.id});
  final int? id;

  @override
  State<ProdutoScreen> createState() => _ProdutoScreenState();
}

class _ProdutoScreenState extends State<ProdutoScreen> {
  late Future<Produto> pedido;
  String? erro;

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

  Future<void> editar(Produto produto) async {
    final salvou = await Navigator.pushNamed(context, AppRoutes.formulario, arguments: produto);
    if (salvou == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> excluir(Produto produto) async {
    final certeza = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir ${produto.nome}?'),
        content: const Text('Tem certeza? O produto sai do seu acervo, e não dá para desfazer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (certeza != true || !mounted) {
      return;
    }
    try {
      await context.read<ProdutoService>().excluir(produto.id);
    } on ErroDeProdutos catch (e) {
      setState(() {
        erro = '$e';
      });
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true); // Devolve true para a lista recarregar
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => editar(produto),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => excluir(produto),
                    icon: const Icon(Icons.delete),
                    label: const Text('Excluir'),
                  ),
                ],
              ),
              if (erro != null) ...[
                const SizedBox(height: 16),
                Text(
                  erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}