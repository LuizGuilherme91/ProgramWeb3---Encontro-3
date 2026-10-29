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

// As regras dos produtos. Não guarda estado (não é um ChangeNotifier).
// Quem lembra se está carregando ou se deu erro é a própria tela.
class ProdutoService {
  ProdutoService(this.repositorio, this.sessao);

  final ProdutoRepository repositorio;
  final SessaoService sessao;

  Future<List<Produto>> listar() async {
    try {
      // O guarda só abre a tela com sessão: o token nunca é null aqui.
      return await repositorio.listar(sessao.token!);
    } on RecusaDaApi catch (e) {
      throw ErroDeProdutos(e.mensagem);
    } on Exception {
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
}