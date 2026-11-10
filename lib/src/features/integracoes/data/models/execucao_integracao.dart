import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/shared/utils/json_utils.dart';

import 'status_execucao.dart';

/// Uma execucao de rotina de integracao, como o backend a devolve.
class ExecucaoIntegracao extends Equatable {
  const ExecucaoIntegracao({
    required this.id,
    required this.processo,
    required this.status,
    this.origem,
    this.iniciadoEm,
    this.finalizadoEm,
    this.duracaoMs,
    this.registrosLidos = 0,
    this.registrosProcessados = 0,
    this.registrosInseridos = 0,
    this.registrosAtualizados = 0,
    this.registrosIgnorados = 0,
    this.mensagemErro,
  });

  final String id;
  final String processo;
  final StatusExecucao status;

  /// AGENDADA ou MANUAL — a tela distingue o que o cron fez do que o
  /// administrador disparou.
  final String? origem;

  final DateTime? iniciadoEm;
  final DateTime? finalizadoEm;
  final int? duracaoMs;

  final int registrosLidos;

  /// Inseridos + atualizados.
  final int registrosProcessados;
  final int registrosInseridos;
  final int registrosAtualizados;
  final int registrosIgnorados;

  final String? mensagemErro;

  bool get foiManual => origem == 'MANUAL';

  factory ExecucaoIntegracao.fromJson(Map<String, dynamic> json) =>
      ExecucaoIntegracao(
        id: json['id']?.toString() ?? '',
        processo: json['processo']?.toString() ?? '',
        status: StatusExecucao.fromApi(json['status']?.toString()),
        origem: json['origem']?.toString(),
        iniciadoEm: parseDateTime(json['iniciadoEm']),
        finalizadoEm: parseDateTime(json['finalizadoEm']),
        duracaoMs: parseIntOrNull(json['duracaoMs']),
        registrosLidos: parseIntOrNull(json['registrosLidos']) ?? 0,
        registrosProcessados: parseIntOrNull(json['registrosProcessados']) ?? 0,
        registrosInseridos: parseIntOrNull(json['registrosInseridos']) ?? 0,
        registrosAtualizados: parseIntOrNull(json['registrosAtualizados']) ?? 0,
        registrosIgnorados: parseIntOrNull(json['registrosIgnorados']) ?? 0,
        mensagemErro: json['mensagemErro']?.toString(),
      );

  @override
  List<Object?> get props => [
        id,
        processo,
        status,
        origem,
        iniciadoEm,
        finalizadoEm,
        duracaoMs,
        registrosLidos,
        registrosProcessados,
        registrosInseridos,
        registrosAtualizados,
        registrosIgnorados,
        mensagemErro,
      ];
}
