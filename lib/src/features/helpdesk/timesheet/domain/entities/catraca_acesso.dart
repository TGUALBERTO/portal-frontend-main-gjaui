import 'package:equatable/equatable.dart';

/// Sentido da passagem na catraca.
enum TipoAcesso {
  entrada('E'),
  saida('S');

  const TipoAcesso(this.api);

  /// Valor usado pelo backend ("E" / "S").
  final String api;

  static TipoAcesso fromApi(String? value) =>
      value?.trim().toUpperCase() == 'S' ? TipoAcesso.saida : TipoAcesso.entrada;

  bool get isEntrada => this == TipoAcesso.entrada;

  String get label => isEntrada ? 'Entrada' : 'Saída';
}

/// Registro de passagem na catraca (histórico de ponto do funcionário),
/// retornado por `GET /acessos/search/findByMatricula` (HAL).
class CatracaAcesso extends Equatable {
  final int origemId;

  /// Momento em que o funcionário passou na catraca (horário local).
  final DateTime data;
  final TipoAcesso tipoAcesso;
  final String matricula;
  final String nome;
  final String cargo;
  final String lotacao;

  /// Nome da catraca em que a passagem ocorreu
  /// (ex.: "Catraca Portaria 1 - (Urna)").
  final String catraca;

  /// Id da catraca na origem (campo `idCatraca`).
  final int? idCatraca;

  const CatracaAcesso({
    required this.origemId,
    required this.data,
    required this.tipoAcesso,
    required this.matricula,
    required this.nome,
    required this.cargo,
    required this.lotacao,
    required this.catraca,
    required this.idCatraca,
  });

  factory CatracaAcesso.fromJson(Map<String, dynamic> json) {
    return CatracaAcesso(
      origemId: (json['origemId'] as num?)?.toInt() ?? 0,
      data: DateTime.parse(json['data'] as String),
      tipoAcesso: TipoAcesso.fromApi(json['tipoAcesso'] as String?),
      matricula: (json['matricula'] as String?) ?? '',
      nome: (json['nome'] as String?) ?? '',
      cargo: (json['cargo'] as String?) ?? '',
      lotacao: (json['lotacao'] as String?) ?? '',
      catraca: (json['catraca'] as String?) ?? '',
      idCatraca: (json['idCatraca'] as num?)?.toInt(),
    );
  }

  /// Catracas do refeitório: a passagem é de refeição, não de expediente.
  static const Set<int> catracasRefeitorio = {23, 65};

  bool get isRefeitorio => catracasRefeitorio.contains(idCatraca);

  @override
  List<Object?> get props => [
        origemId,
        data,
        tipoAcesso,
        matricula,
        nome,
        cargo,
        lotacao,
        catraca,
        idCatraca,
      ];
}
