/// Uma rota da estrutura comercial do período (`RH_PROC.ESTRUTURA_COMERCIAL`),
/// com a hierarquia: consultor, supervisor, gerente de vendas e gerente
/// comercial. O id `99999` é a convenção do legado para "sem gestor".
class EstruturaRota {
  const EstruturaRota({
    required this.periodo,
    required this.unidade,
    required this.rota,
    required this.matriculaConsultor,
    required this.nomeConsultor,
    this.idSupervisao,
    this.descricaoSupervisao,
    this.matriculaSupervisor,
    this.nomeSupervisor,
    this.idGerenciaVendas,
    this.descricaoGerenciaVendas,
    this.matriculaGerenteVendas,
    this.nomeGerenteVendas,
    this.idGerenciaComercial,
    this.descricaoGerenciaComercial,
    this.matriculaGerenteComercial,
    this.nomeGerenteComercial,
  });

  factory EstruturaRota.fromJson(Map<String, dynamic> json) => EstruturaRota(
        periodo: '${json['periodo'] ?? ''}',
        unidade: json['unidade'] as String? ?? '',
        rota: json['rota'] as String? ?? '',
        matriculaConsultor: json['matriculaConsultor'] as String? ?? '',
        nomeConsultor: json['nomeConsultor'] as String? ?? '',
        idSupervisao: json['idSupervisao'] as String?,
        descricaoSupervisao: json['descricaoSupervisao'] as String?,
        matriculaSupervisor: json['matriculaSupervisor'] as String?,
        nomeSupervisor: json['nomeSupervisor'] as String?,
        idGerenciaVendas: json['idGerenciaVendas'] as String?,
        descricaoGerenciaVendas: json['descricaoGerenciaVendas'] as String?,
        matriculaGerenteVendas: json['matriculaGerenteVendas'] as String?,
        nomeGerenteVendas: json['nomeGerenteVendas'] as String?,
        idGerenciaComercial: json['idGerenciaComercial'] as String?,
        descricaoGerenciaComercial:
            json['descricaoGerenciaComercial'] as String?,
        matriculaGerenteComercial: json['matriculaGerenteComercial'] as String?,
        nomeGerenteComercial: json['nomeGerenteComercial'] as String?,
      );

  /// `yyyymm`.
  final String periodo;
  final String unidade;
  final String rota;
  final String matriculaConsultor;
  final String nomeConsultor;
  final String? idSupervisao;
  final String? descricaoSupervisao;
  final String? matriculaSupervisor;
  final String? nomeSupervisor;
  final String? idGerenciaVendas;
  final String? descricaoGerenciaVendas;
  final String? matriculaGerenteVendas;
  final String? nomeGerenteVendas;
  final String? idGerenciaComercial;
  final String? descricaoGerenciaComercial;
  final String? matriculaGerenteComercial;
  final String? nomeGerenteComercial;

  /// Corpo de `PUT /estrutura-comercial/{periodo}/{unidade}/{rota}`: período,
  /// unidade e rota vão na URL.
  Map<String, dynamic> toAlteracaoJson() => {
        'matriculaConsultor': matriculaConsultor,
        'nomeConsultor': nomeConsultor,
        'idSupervisao': idSupervisao,
        'descricaoSupervisao': descricaoSupervisao,
        'matriculaSupervisor': matriculaSupervisor,
        'nomeSupervisor': nomeSupervisor,
        'idGerenciaVendas': idGerenciaVendas,
        'descricaoGerenciaVendas': descricaoGerenciaVendas,
        'matriculaGerenteVendas': matriculaGerenteVendas,
        'nomeGerenteVendas': nomeGerenteVendas,
        'idGerenciaComercial': idGerenciaComercial,
        'descricaoGerenciaComercial': descricaoGerenciaComercial,
        'matriculaGerenteComercial': matriculaGerenteComercial,
        'nomeGerenteComercial': nomeGerenteComercial,
      };

  /// Cópia com a nova hierarquia; campo vazio vira `null` (sem gestor).
  EstruturaRota copyWith({
    String? matriculaConsultor,
    String? nomeConsultor,
    String? matriculaSupervisor,
    String? nomeSupervisor,
    String? matriculaGerenteVendas,
    String? nomeGerenteVendas,
    String? matriculaGerenteComercial,
    String? nomeGerenteComercial,
  }) {
    String? limpo(String? novo, String? atual) {
      if (novo == null) return atual;
      final t = novo.trim();
      return t.isEmpty ? null : t;
    }

    return EstruturaRota(
      periodo: periodo,
      unidade: unidade,
      rota: rota,
      matriculaConsultor: matriculaConsultor?.trim() ?? this.matriculaConsultor,
      nomeConsultor: nomeConsultor?.trim() ?? this.nomeConsultor,
      idSupervisao: idSupervisao,
      descricaoSupervisao: descricaoSupervisao,
      matriculaSupervisor: limpo(matriculaSupervisor, this.matriculaSupervisor),
      nomeSupervisor: limpo(nomeSupervisor, this.nomeSupervisor),
      idGerenciaVendas: idGerenciaVendas,
      descricaoGerenciaVendas: descricaoGerenciaVendas,
      matriculaGerenteVendas:
          limpo(matriculaGerenteVendas, this.matriculaGerenteVendas),
      nomeGerenteVendas: limpo(nomeGerenteVendas, this.nomeGerenteVendas),
      idGerenciaComercial: idGerenciaComercial,
      descricaoGerenciaComercial: descricaoGerenciaComercial,
      matriculaGerenteComercial:
          limpo(matriculaGerenteComercial, this.matriculaGerenteComercial),
      nomeGerenteComercial:
          limpo(nomeGerenteComercial, this.nomeGerenteComercial),
    );
  }

  /// Identidade da rota no período (unidade + rota).
  String get chave => '$unidade|$rota';
}

/// Resposta de `POST /estrutura-comercial/importacoes`.
class ResultadoImportacao {
  const ResultadoImportacao({
    required this.periodo,
    required this.rotasNoWorkflow,
    required this.rotasExistentes,
    required this.rotasIncluidas,
  });

  factory ResultadoImportacao.fromJson(Map<String, dynamic> json) =>
      ResultadoImportacao(
        periodo: json['periodo'] as String? ?? '',
        rotasNoWorkflow: (json['rotasNoWorkflow'] as num?)?.toInt() ?? 0,
        rotasExistentes: (json['rotasExistentes'] as num?)?.toInt() ?? 0,
        rotasIncluidas: (json['rotasIncluidas'] as num?)?.toInt() ?? 0,
      );

  final String periodo;
  final int rotasNoWorkflow;
  final int rotasExistentes;
  final int rotasIncluidas;
}
