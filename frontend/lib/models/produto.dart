// O produto como o app o conhece: o mesmo ProdutoPublico que a API devolve.
class Produto {
  Produto({
    required this.id,
    required this.nome,
    required this.preco,
    required this.emEstoque,
  });

  final int id;
  final String nome;
  final double preco;
  final bool emEstoque;

  // Monta um Produto a partir de um item do JSON da API:
  // {"id": 1, "nome": "Cadeira", "preco": 150.0, "em_estoque": true, ...}.
  // O que o app não usa (como dono_id) fica de fora.
  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'],
      nome: json['nome'],
      preco: (json['preco'] as num).toDouble(),
      emEstoque: json['em_estoque'],
    );
  }
}