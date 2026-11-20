import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/produto.dart';
import '../services/produto_service.dart';
import '../widgets/aviso.dart';
import 'produtos_screen.dart';

// Uma tela só para criar e para editar: sem produto, cria; com produto, edita.
class FormularioScreen extends StatefulWidget {
  const FormularioScreen({super.key, this.produto});

  // O produto a editar, vindo nos arguments; null é um produto novo.
  final Produto? produto;

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final chave = GlobalKey<FormState>();
  final nome = TextEditingController();
  final preco = TextEditingController();
  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    if (widget.produto != null) {
      nome.text = widget.produto!.nome;
      preco.text = widget.produto!.preco.toStringAsFixed(2);
    }
  }

  Future<void> salvar() async {
    if (!chave.currentState!.validate()) {
      return;
    }
    setState(() {
      salvando = true;
      erro = null;
    });
    final servico = context.read<ProdutoService>();
    final valorPreco = double.parse(preco.text.trim().replaceAll(',', '.'));
    try {
      if (widget.produto == null) {
        await servico.criar(nome.text.trim(), valorPreco);
      } else {
        await servico.atualizar(
          widget.produto!.id,
          nome.text.trim(),
          valorPreco,
        );
      }
    } on ErroDeProdutos catch (e) {
      if (!mounted) return;
      setState(() {
        salvando = false;
        erro = '$e';
      });
      avisar(context, 'Não deu para salvar', erro: true);
      return;
    }
    if (!mounted) return;
    avisar(context, 'Produto salvo');
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    nome.dispose();
    preco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Depois de um F5, o formulário é a primeira tela da pilha: mostra a lista.
    if (ModalRoute.of(context)!.isFirst) {
      return const ProdutosScreen();
    }
    final editando = widget.produto != null;
    return Scaffold(
      appBar: AppBar(title: Text(editando ? 'Editar produto' : 'Novo produto')),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: chave,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nome,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if ((valor ?? '').trim().isEmpty) {
                        return 'Informe o nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: preco,
                    decoration: const InputDecoration(
                      labelText: 'Preço',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (valor) {
                      final texto = (valor ?? '').trim().replaceAll(',', '.');
                      if (double.tryParse(texto) == null) {
                        return 'Informe o preço, só com números';
                      }
                      return null;
                    },
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      erro!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: salvando ? null : salvar,
                    child: Text(salvando ? 'Salvando...' : 'Salvar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
