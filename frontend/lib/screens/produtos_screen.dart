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
  String busca = '';
  // Filtro "Só em estoque": ligado, a API devolve só os produtos com em_estoque=true.
  bool soEmEstoque = false;
  // Controller do campo de busca: permite ao botão x apagar o texto digitado.
  final campoDaBusca = TextEditingController();

  @override
  void initState() {
    super.initState();
    produtos = context.read<ProdutoService>().listar();
  }

  @override
  void dispose() {
    campoDaBusca.dispose();
    super.dispose();
  }

  void pedirDeNovo() {
    setState(() {
      produtos = context.read<ProdutoService>().listar(
        busca: busca,
        soEmEstoque: soEmEstoque,
      );
    });
  }

  void buscar(String texto) {
    busca = texto.trim();
    pedirDeNovo();
  }

  // O x no fim do campo: apaga o texto e recarrega sem busca.
  void limparABusca() {
    campoDaBusca.clear();
    buscar('');
  }

  // O toque no chip: liga ou desliga o filtro, mantendo a busca atual.
  void filtrar(bool ligado) {
    soEmEstoque = ligado;
    pedirDeNovo();
  }

  Widget listaDosProdutos() {
    return FutureBuilder<List<Produto>>(
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
          final String frase;
          if (busca.isNotEmpty) {
            frase = 'Nenhum produto com "$busca" no nome.';
          } else if (soEmEstoque) {
            frase = 'Nenhum produto em estoque agora.';
          } else {
            frase = 'Nenhum produto ainda.';
          }
          return Center(child: Text(frase));
        }
        return ListView.builder(
          itemCount: lista.length,
          itemBuilder: (context, i) {
            final produto = lista[i];
            return ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: Text(produto.nome),
              subtitle: Text('R\$ ${produto.preco.toStringAsFixed(2)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final mudou = await Navigator.pushNamed(
                  context,
                  AppRoutes.produto,
                  arguments: produto.id,
                );
                if (mudou == true) {
                  pedirDeNovo();
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: campoDaBusca,
              decoration: InputDecoration(
                labelText: 'Buscar pelo nome',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpar a busca',
                  onPressed: limparABusca,
                ),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: buscar,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Só em estoque'),
                selected: soEmEstoque,
                onSelected: filtrar,
              ),
            ),
          ),
          Expanded(child: listaDosProdutos()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo produto',
        onPressed: () async {
          final salvou = await Navigator.pushNamed(
            context,
            AppRoutes.formulario,
          );
          if (salvou == true) {
            pedirDeNovo();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
