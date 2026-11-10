/// Produto do cadastro de características. Sem característica, [grupo] e
/// [subgrupo] vêm nulos (`GET /produtos?caracterizado=false`).
class Produto {
  const Produto({
    required this.codigo,
    required this.descricao,
    required this.fator,
    this.grupo,
    this.subgrupo,
  });

  factory Produto.fromJson(Map<String, dynamic> json) => Produto(
        codigo: json['codigo'] as String? ?? '',
        descricao: json['descricao'] as String? ?? '',
        fator: (json['fator'] as num?)?.toDouble(),
        grupo: json['grupo'] as String?,
        subgrupo: json['subgrupo'] as String?,
      );

  /// Código normalizado (sem zeros à esquerda), usado na URL da API.
  final String codigo;
  final String descricao;

  /// Fator de conversão para caixa unitária (CXU).
  final double? fator;
  final String? grupo;
  final String? subgrupo;

  bool get caracterizado => grupo != null && grupo!.isNotEmpty;
}
