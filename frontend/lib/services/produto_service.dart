import '../models/produto.dart';
import '../repositories/produto_repository.dart';
import '../repositories/usuario_repository.dart';
import 'sessao_service.dart';

// A recusa dos produtos, com a frase que a tela mostra.
class ErroDeProdutos implements Exception {
  ErroDeProdutos(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

// As regras dos produtos: pega o token na sessão, pede ao repositório e traduz a recusa.
class ProdutoService {
  ProdutoService(this.repositorio, this.sessao);

  final ProdutoRepository repositorio;
  final SessaoService sessao;

  // A lista inteira, ou só a que passa nos filtros: busca no nome e "só em estoque".
  Future<List<Produto>> listar({
    String busca = '',
    bool soEmEstoque = false,
  }) async {
    try {
      return await repositorio.listar(
        sessao.token!,
        busca: busca,
        soEmEstoque: soEmEstoque,
      );
    } on RecusaDaApi catch (e) {
      throw ErroDeProdutos(e.mensagem);
    } on Exception {
      throw ErroDeProdutos(
        'Não consegui falar com a API. O uvicorn está rodando?',
      );
    }
  }

  Future<Produto> buscar(int id) async {
    try {
      return await repositorio.buscar(sessao.token!, id);
    } on RecusaDaApi catch (e) {
      throw ErroDeProdutos(e.mensagem);
    } on Exception {
      throw ErroDeProdutos(
        'Não consegui falar com a API. O uvicorn está rodando?',
      );
    }
  }

  Future<Produto> criar(String nome, double preco) async {
    try {
      return await repositorio.criar(sessao.token!, nome, preco);
    } on RecusaDaApi catch (e) {
      throw ErroDeProdutos(e.mensagem);
    } on Exception {
      throw ErroDeProdutos(
        'Não consegui falar com a API. O uvicorn está rodando?',
      );
    }
  }

  Future<Produto> atualizar(int id, String nome, double preco) async {
    try {
      return await repositorio.atualizar(sessao.token!, id, nome, preco);
    } on RecusaDaApi catch (e) {
      throw ErroDeProdutos(e.mensagem);
    } on Exception {
      throw ErroDeProdutos(
        'Não consegui falar com a API. O uvicorn está rodando?',
      );
    }
  }

  Future<void> excluir(int id) async {
    try {
      await repositorio.excluir(sessao.token!, id);
    } on RecusaDaApi catch (e) {
      throw ErroDeProdutos(e.mensagem);
    } on Exception {
      throw ErroDeProdutos(
        'Não consegui falar com a API. O uvicorn está rodando?',
      );
    }
  }
}
