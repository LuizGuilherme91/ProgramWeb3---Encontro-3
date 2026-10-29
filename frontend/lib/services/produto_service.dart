import '../models/produto.dart';
import '../repositories/produto_repository.dart';
import '../repositories/usuario_repository.dart';
import 'sessao_service.dart';

// A recusa dos produtos, com a frase que a tela mostra.
class ErroDeProdutos implements Exception {
  ErroDeProdutos(this.mensagem);

  final String mensagem;

  // O texto do erro quando a tela o mostra: é o __str__ do Python.
  @override
  String toString() => mensagem;
}

// As regras dos produtos. Não guarda estado (não é um ChangeNotifier): quem
// lembra se está carregando, se deu erro ou qual é a lista é a própria tela.
class ProdutoService {
  ProdutoService(this.repositorio, this.sessao);

  final ProdutoRepository repositorio;
  final SessaoService sessao;

  Future<List<Produto>> listar() async {
    try {
      // O guarda só abre a tela protegida com sessão: o token nunca é null aqui.
      return await repositorio.listar(sessao.token!);
    } on RecusaDaApi catch (e) {
      throw ErroDeProdutos(e.mensagem);
    } on Exception {
      // Uma falha de fora, como a rede: a API nem respondeu (o uvicorn parado).
      throw ErroDeProdutos('Não consegui falar com a API. O uvicorn está rodando?');
    }
  }

  Future<Produto> buscar(int id) async {
    try {
      return await repositorio.buscar(sessao.token!, id);
    } on RecusaDaApi catch (e) {
      throw ErroDeProdutos(e.mensagem);
    } on Exception {
      throw ErroDeProdutos('Não consegui falar com a API. O uvicorn está rodando?');
    }
  }

  // Criar, editar e excluir: o mesmo molde do listar. O token vem da sessão,
  // e a recusa da API (422, 409, 404) vira a frase que a tela mostra.
  Future<Produto> criar(String nome, double preco) async {
    try {
      return await repositorio.criar(sessao.token!, nome, preco);
    } on RecusaDaApi catch (e) {
      throw ErroDeProdutos(e.mensagem);
    } on Exception {
      throw ErroDeProdutos('Não consegui falar com a API. O uvicorn está rodando?');
    }
  }

  Future<Produto> atualizar(int id, String nome, double preco) async {
    try {
      return await repositorio.atualizar(sessao.token!, id, nome, preco);
    } on RecusaDaApi catch (e) {
      throw ErroDeProdutos(e.mensagem);
    } on Exception {
      throw ErroDeProdutos('Não consegui falar com a API. O uvicorn está rodando?');
    }
  }

  Future<void> excluir(int id) async {
    try {
      await repositorio.excluir(sessao.token!, id);
    } on RecusaDaApi catch (e) {
      throw ErroDeProdutos(e.mensagem);
    } on Exception {
      throw ErroDeProdutos('Não consegui falar com a API. O uvicorn está rodando?');
    }
  }
}