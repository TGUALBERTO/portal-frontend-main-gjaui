/// Uma rota da estrutura comercial, com o consultor responsável.
class RotaComercial {
  const RotaComercial({
    required this.unidade,
    required this.rota,
    required this.matriculaConsultor,
    required this.nomeConsultor,
  });

  factory RotaComercial.fromJson(Map<String, dynamic> json) => RotaComercial(
        unidade: json['unidade'] as String? ?? '',
        rota: json['rota'] as String? ?? '',
        matriculaConsultor: json['matriculaConsultor'] as String? ?? '',
        nomeConsultor: json['nomeConsultor'] as String? ?? '',
      );

  final String unidade;
  final String rota;
  final String matriculaConsultor;
  final String nomeConsultor;
}

/// Consultor ou supervisor resolvido na estrutura comercial do período, com as
/// rotas sob sua responsabilidade.
class EquipeVendas {
  const EquipeVendas({
    required this.matricula,
    required this.nome,
    required this.rotas,
  });

  factory EquipeVendas.fromJson(Map<String, dynamic> json) => EquipeVendas(
        matricula: json['matricula'] as String? ?? '',
        nome: json['nome'] as String? ?? '',
        rotas: (json['rotas'] as List<dynamic>? ?? const [])
            .map((e) => RotaComercial.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  final String matricula;
  final String nome;
  final List<RotaComercial> rotas;

  /// Códigos das rotas sem repetição, na ordem da API (unidade, rota).
  List<String> get codigosRotas =>
      rotas.map((r) => r.rota).toSet().toList(growable: false);
}
