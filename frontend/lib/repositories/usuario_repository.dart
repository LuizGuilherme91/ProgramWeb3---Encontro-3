import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/usuario.dart';

// Onde a API roda. Na nuvem, o endereço vem de fora, na hora de construir o app
// (--dart-define=API_URL=...); sem ele, o uvicorn, na porta de sempre.
const enderecoDaApi = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

// Uma recusa da API (401, 404, 409, 422), com o status e a frase extraída do JSON.
class RecusaDaApi implements Exception {
  RecusaDaApi(this.status, this.mensagem);

  final int status;
  final String mensagem;
}

// O repositório do usuário: o único que conhece endereço, HTTP e JSON das contas.
class UsuarioRepository {
  UsuarioRepository({http.Client? cliente})
    : cliente = cliente ?? http.Client();

  final http.Client cliente;

  // POST /usuarios/login: manda e-mail e senha no formato de formulário OAuth2.
  Future<String?> entrar(String email, String senha) async {
    final resposta = await cliente.post(
      Uri.parse('$enderecoDaApi/usuarios/login'),
      body: {'username': email, 'password': senha},
    );
    if (resposta.statusCode != 200) {
      return null;
    }
    return jsonDecode(resposta.body)['access_token'] as String;
  }

  // POST /usuarios/: cria a conta e devolve o usuário criado (201).
  Future<Usuario> cadastrar(String nome, String email, String senha) async {
    final resposta = await cliente.post(
      Uri.parse('$enderecoDaApi/usuarios/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nome': nome, 'email': email, 'senha': senha}),
    );
    if (resposta.statusCode != 201) {
      throw RecusaDaApi(resposta.statusCode, _frase(resposta.body));
    }
    return Usuario.fromJson(jsonDecode(resposta.body));
  }

  // GET /usuarios/eu: devolve os dados do dono do token.
  Future<Usuario> quemSouEu(String token) async {
    final resposta = await cliente.get(
      Uri.parse('$enderecoDaApi/usuarios/eu'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resposta.statusCode != 200) {
      throw RecusaDaApi(resposta.statusCode, _frase(resposta.body));
    }
    return Usuario.fromJson(jsonDecode(resposta.body));
  }

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
