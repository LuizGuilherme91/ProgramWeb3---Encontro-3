import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/produto.dart';
import '../services/produto_service.dart';
import 'produtos_screen.dart';

// Uma tela só para criar e para editar: sem produto, cria; com produto, edita.
class FormularioScreen extends StatefulWidget {
  const FormularioScreen({super.key, this.produto});

  // O produto a editar, que veio nos arguments; null é um produto novo.
  final Produto? produto;

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  // A chave do Form: é por ela que o Salvar alcança o formulário e confere tudo.
  final chave = GlobalKey<FormState>();
  final nome = TextEditingController();
  final preco = TextEditingController();
  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    // Editando: os campos já começam preenchidos.
    if (widget.produto != null) {
      nome.text = widget.produto!.nome;
      preco.text = '${widget.produto!.preco}';
    }
  }

  Future<void> salvar() async {
    // A ponta do app: confere os campos localmente.
    if (!chave.currentState!.validate()) {
      return;
    }
    setState(() {
      salvando = true;
      erro = null;
    });
    
    // A ponta da API: ela confere tudo de novo, e pode recusar.
    final servico = context.read<ProdutoService>();
    try {
      if (widget.produto == null) {
        await servico.criar(nome.text, double.parse(preco.text));
      } else {
        await servico.atualizar(widget.produto!.id, nome.text, double.parse(preco.text));
      }
    } on ErroDeProdutos catch (e) {
      setState(() {
        salvando = false;
        erro = '$e';
      });
      return;
    }
    if (!mounted) return;
    
    // Deu certo: o formulário fecha com true, e quem o abriu (lista/detalhe) pede de novo.
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
                      labelText: 'Nome do Produto',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if ((valor ?? '').trim().isEmpty) {
                        return 'Informe o nome do produto';
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
                    keyboardType: TextInputType.number,
                    validator: (valor) {
                      if (double.tryParse(valor ?? '') == null) {
                        return 'Informe o preço, apenas com números e ponto (ex: 150.50)';
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