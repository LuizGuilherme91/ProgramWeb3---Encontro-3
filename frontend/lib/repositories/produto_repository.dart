import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/produto.dart';
import 'usuario_repository.dart';

// O repositório dos produtos: o único que sabe endereço, HTTP e JSON.
// O enderecoDaApi e a RecusaDaApi vêm do usuario_repository.dart.
class ProdutoRepository {
  ProdutoRepository({http.Client? cliente}) : cliente = cliente ?? http.Client();

  final http.Client cliente;

  // GET /produtos/, com o token no cabeçalho.
  Future<List<Produto>> listar(String token) async {
    final resposta = await cliente.get(
      Uri.parse('$enderecoDaApi/produtos/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resposta.statusCode != 200) {
      throw RecusaDaApi(resposta.statusCode, _frase(resposta.body));
    }
    final itens = jsonDecode(resposta.body) as List;
    return [for (final item in itens) Produto.fromJson(item)];
  }

  // GET /produtos/{id}: um produto só.
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

  // PATCH /produtos/{id}: edita apenas o nome e o preço.
  // A situação de estoque não é editada nesta rota, de acordo com o design da API.
  Future<Produto> atualizar(String token, int id, String nome, double preco) async {
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

  // DELETE /produtos/{id}: a API responde 204, sem corpo.
  Future<void> excluir(String token, int id) async {
    final resposta = await cliente.delete(
      Uri.parse('$enderecoDaApi/produtos/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resposta.statusCode != 204) {
      throw RecusaDaApi(resposta.statusCode, _frase(resposta.body));
    }
  }

  // A frase da recusa, como no UsuarioRepository: extrai o texto do "detail".
  // Remove mensagens excessivas do Pydantic, como "Value error, ".
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