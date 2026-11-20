import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/produto.dart';
import 'usuario_repository.dart';

// O repositório dos produtos: o único que conhece endereço, HTTP e JSON.
class ProdutoRepository {
  ProdutoRepository({http.Client? cliente})
    : cliente = cliente ?? http.Client();

  final http.Client cliente;

  // GET /produtos/, com o token no cabeçalho. Cada filtro escolhido vira um
  // parâmetro de consulta: a busca (?nome=) e o "só em estoque" (?em_estoque=true).
  // Os dois juntos: ?nome=cade&em_estoque=true.
  Future<List<Produto>> listar(
    String token, {
    String busca = '',
    bool soEmEstoque = false,
  }) async {
    var endereco = Uri.parse('$enderecoDaApi/produtos/');
    // O if dentro do mapa faz a chave entrar só quando o filtro foi escolhido.
    final filtros = {
      if (busca.isNotEmpty) 'nome': busca,
      if (soEmEstoque) 'em_estoque': 'true',
    };
    if (filtros.isNotEmpty) {
      // O replace monta o ?nome=...&em_estoque=... e codifica espaços e acentos.
      endereco = endereco.replace(queryParameters: filtros);
    }
    final resposta = await cliente.get(
      endereco,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resposta.statusCode != 200) {
      throw RecusaDaApi(resposta.statusCode, _frase(resposta.body));
    }
    final itens = jsonDecode(resposta.body);
    return [for (final item in itens) Produto.fromJson(item)];
  }

  // GET /produtos/{id}: um produto só, como ele está AGORA no banco.
  Future<Produto> buscar(String token, int id) async {
    final resposta = await cliente.get(
      Uri.parse('$enderecoDaApi/produtos/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resposta.statusCode != 200) {
      throw RecusaDaApi(resposta.statusCode, _frase(resposta.body));
    }
    return Produto.fromJson(jsonDecode(resposta.body));
  }

  // POST /produtos/: o produto novo vai em JSON no corpo e o token no cabeçalho.
  Future<Produto> criar(String token, String nome, double preco) async {
    final resposta = await cliente.post(
      Uri.parse('$enderecoDaApi/produtos/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'nome': nome, 'preco': preco}),
    );
    if (resposta.statusCode != 201) {
      throw RecusaDaApi(resposta.statusCode, _frase(resposta.body));
    }
    return Produto.fromJson(jsonDecode(resposta.body));
  }

  // PATCH /produtos/{id}: só o que o formulário edita, nome e preço.
  Future<Produto> atualizar(
    String token,
    int id,
    String nome,
    double preco,
  ) async {
    final resposta = await cliente.patch(
      Uri.parse('$enderecoDaApi/produtos/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'nome': nome, 'preco': preco}),
    );
    if (resposta.statusCode != 200) {
      throw RecusaDaApi(resposta.statusCode, _frase(resposta.body));
    }
    return Produto.fromJson(jsonDecode(resposta.body));
  }

  // DELETE /produtos/{id}: a API responde 204, sem corpo nenhum.
  Future<void> excluir(String token, int id) async {
    final resposta = await cliente.delete(
      Uri.parse('$enderecoDaApi/produtos/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resposta.statusCode != 204) {
      throw RecusaDaApi(resposta.statusCode, _frase(resposta.body));
    }
  }

  // Extrai a mensagem de erro do "detail" retornado pelo FastAPI/Pydantic.
  String _frase(String corpo) {
    final detalhe = jsonDecode(corpo)['detail'];
    if (detalhe is String) {
      return detalhe;
    }
    final primeiro = detalhe[0];
    final mensagem = '${primeiro['msg']}'.replaceFirst('Value error, ', '');
    return '${primeiro['loc'].last}: $mensagem';
  }
}
