import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/shared/utils/json_utils.dart';

import 'execucao_integracao.dart';
import 'status_execucao.dart';
import 'tipo_processo.dart';

/// Um processo de integracao na tela de gerenciamento: o que e, se pode rodar
/// agora e o que aconteceu da ultima vez.
class ProcessoIntegracao extends Equatable {
  const ProcessoIntegracao({
    required this.nome,
    required this.descricao,
    required this.tipo,
    required this.grupoRecurso,
    required this.requisitos,
    required this.ativo,
    required this.disparoManual,
    required this.bloqueado,
    required this.emExecucao,
    required this.podeExecutar,
    this.bloqueadoPor,
    this.motivoIndisponivel,
    this.cron,
    this.chaveCron,
    this.proximaExecucao,
    this.ultimaExecucao,
  });

  final String nome;
  final String descricao;
  final TipoProcesso tipo;

  /// Processos do mesmo grupo nunca rodam ao mesmo tempo.
  final String grupoRecurso;

  /// Integracoes exigidas (ex.: "Oracle + Helpdesk").
  final String requisitos;

  /// A rotina existe neste ambiente. Quando falsa, o processo aparece na lista
  /// marcado como desativado em vez de sumir.
  final bool ativo;

  final bool disparoManual;

  /// Ha execucao viva no mesmo grupo de recurso.
  final bool bloqueado;
  final String? bloqueadoPor;

  /// E este processo que esta rodando agora.
  final bool emExecucao;

  /// Habilita o botao "Executar agora".
  final bool podeExecutar;

  /// Por que o botao esta desabilitado (tooltip).
  final String? motivoIndisponivel;

  final String? cron;
  final String? chaveCron;
  final DateTime? proximaExecucao;
  final ExecucaoIntegracao? ultimaExecucao;

  /// Status exibido: o da execucao em curso quando ha uma, senao o da ultima.
  StatusExecucao get statusExibido => emExecucao
      ? StatusExecucao.executando
      : ultimaExecucao?.status ?? StatusExecucao.desconhecido;

  /// Precisa de polling: algo esta rodando ou aguardando vez.
  bool get temAtividade => emExecucao || bloqueado || statusExibido.isTransitorio;

  factory ProcessoIntegracao.fromJson(Map<String, dynamic> json) {
    final ultima = json['ultimaExecucao'];
    return ProcessoIntegracao(
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      tipo: TipoProcesso.fromApi(json['tipo']?.toString()),
      grupoRecurso: json['grupoRecurso']?.toString() ?? '',
      requisitos: json['requisitos']?.toString() ?? '',
      ativo: parseBool(json['ativo']),
      disparoManual: parseBool(json['disparoManual']),
      bloqueado: parseBool(json['bloqueado']),
      emExecucao: parseBool(json['emExecucao']),
      podeExecutar: parseBool(json['podeExecutar']),
      bloqueadoPor: json['bloqueadoPor']?.toString(),
      motivoIndisponivel: json['motivoIndisponivel']?.toString(),
      cron: json['cron']?.toString(),
      chaveCron: json['chaveCron']?.toString(),
      proximaExecucao: parseDateTime(json['proximaExecucao']),
      ultimaExecucao: ultima is Map<String, dynamic>
          ? ExecucaoIntegracao.fromJson(ultima)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        nome,
        descricao,
        tipo,
        grupoRecurso,
        requisitos,
        ativo,
        disparoManual,
        bloqueado,
        bloqueadoPor,
        emExecucao,
        podeExecutar,
        motivoIndisponivel,
        cron,
        chaveCron,
        proximaExecucao,
        ultimaExecucao,
      ];
}
