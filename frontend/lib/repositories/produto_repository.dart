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
  // A API devolve os produtos do dono do token em uma LISTA JSON.
  Future<List<Produto>> listar(String token) async {
    final resposta = await cliente.get(
      Uri.parse('$enderecoDaApi/produtos/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resposta.statusCode != 200) {
      throw RecusaDaApi(resposta.statusCode, jsonDecode(resposta.body)['detail']);
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
      throw RecusaDaApi(resposta.statusCode, jsonDecode(resposta.body)['detail']);
    }
    return Produto.fromJson(jsonDecode(resposta.body));
  }
}