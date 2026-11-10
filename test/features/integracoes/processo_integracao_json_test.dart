import 'package:flutter_test/flutter_test.dart';

import 'package:gjamobile/src/features/integracoes/data/models/models.dart';

/// Contrato com o backend. O parsing e tolerante de proposito: um campo novo
/// ou um estado desconhecido nao pode derrubar a tela de diagnostico das
/// integracoes, que e justamente onde alguem vai olhar quando algo quebrar.
void main() {
  test('processo completo é lido campo a campo', () {
    final processo = ProcessoIntegracao.fromJson(const {
      'nome': 'funcionario-fpw-completo',
      'descricao': 'Carga completa de funcionários.',
      'tipo': 'CARGA_COMPLETA',
      'grupoRecurso': 'funcionarios-fpw',
      'requisitos': 'Oracle + Helpdesk',
      'ativo': true,
      'disparoManual': true,
      'bloqueado': false,
      'emExecucao': false,
      'podeExecutar': true,
      'cron': '0 30 3 ? * SUN',
      'chaveCron': 'delta.funcionario-fpw-completo.cron',
      'proximaExecucao': '2026-09-06T03:30:00-03:00',
      'ultimaExecucao': {
        'id': 'e1',
        'processo': 'funcionario-fpw-completo',
        'status': 'CONCLUIDO',
        'origem': 'MANUAL',
        'iniciadoEm': '2026-08-30T03:30:00-03:00',
        'finalizadoEm': '2026-08-30T03:58:12-03:00',
        'duracaoMs': 1692000,
        'registrosLidos': 41230,
        'registrosProcessados': 1204,
        'registrosInseridos': 30,
        'registrosAtualizados': 1174,
        'registrosIgnorados': 40026,
      },
    });

    expect(processo.nome, 'funcionario-fpw-completo');
    expect(processo.tipo, TipoProcesso.cargaCompleta);
    expect(processo.grupoRecurso, 'funcionarios-fpw');
    expect(processo.podeExecutar, isTrue);
    expect(processo.proximaExecucao, isNotNull);
    expect(processo.ultimaExecucao?.status, StatusExecucao.concluido);
    expect(processo.ultimaExecucao?.registrosAtualizados, 1174);
    expect(processo.ultimaExecucao?.foiManual, isTrue);
  });

  test('processo que nunca executou não tem última execução', () {
    final processo = ProcessoIntegracao.fromJson(const {
      'nome': 'acesso',
      'descricao': 'Acessos de catraca.',
      'tipo': 'DELTA',
      'grupoRecurso': 'acesso',
      'requisitos': 'Oracle + Helpdesk',
      'ativo': true,
      'disparoManual': true,
      'bloqueado': false,
      'emExecucao': false,
      'podeExecutar': true,
    });

    expect(processo.ultimaExecucao, isNull);
    expect(processo.proximaExecucao, isNull);
    expect(processo.cron, isNull);
    expect(processo.statusExibido, StatusExecucao.desconhecido);
    expect(processo.temAtividade, isFalse);
  });

  test('processo desativado no ambiente é lido sem erro', () {
    final processo = ProcessoIntegracao.fromJson(const {
      'nome': 'edi',
      'descricao': 'Importação EDI.',
      'tipo': 'DELTA',
      'grupoRecurso': 'edi',
      'requisitos': 'AS/400 (EDI)',
      'ativo': false,
      'disparoManual': true,
      'bloqueado': false,
      'emExecucao': false,
      'podeExecutar': false,
      'motivoIndisponivel': 'Integracao desativada neste ambiente.',
    });

    expect(processo.ativo, isFalse);
    expect(processo.podeExecutar, isFalse);
    expect(processo.motivoIndisponivel, contains('desativada'));
  });

  test('status desconhecido não quebra o parsing', () {
    // O backend pode ganhar um estado novo antes do app ser atualizado.
    final execucao = ExecucaoIntegracao.fromJson(const {
      'id': 'e9',
      'processo': 'chamado',
      'status': 'PAUSADO_POR_ALGUM_MOTIVO',
    });

    expect(execucao.status, StatusExecucao.desconhecido);
    expect(execucao.status.isTransitorio, isFalse);
  });

  test('tipo desconhecido cai no rótulo genérico', () {
    final processo = ProcessoIntegracao.fromJson(const {
      'nome': 'novo',
      'descricao': 'x',
      'tipo': 'ALGO_NOVO',
      'grupoRecurso': 'g',
      'requisitos': 'r',
      'ativo': true,
      'disparoManual': true,
      'bloqueado': false,
      'emExecucao': false,
      'podeExecutar': true,
    });

    expect(processo.tipo, TipoProcesso.desconhecido);
    expect(processo.tipo.label, 'Outro');
  });

  test('execução em curso é transitória e conta como atividade', () {
    final processo = ProcessoIntegracao.fromJson(const {
      'nome': 'funcionario-fpw-completo',
      'descricao': 'x',
      'tipo': 'CARGA_COMPLETA',
      'grupoRecurso': 'funcionarios-fpw',
      'requisitos': 'r',
      'ativo': true,
      'disparoManual': true,
      'bloqueado': true,
      'bloqueadoPor': 'funcionario-fpw-completo',
      'emExecucao': true,
      'podeExecutar': false,
      'ultimaExecucao': {
        'id': 'e2',
        'processo': 'funcionario-fpw-completo',
        'status': 'EXECUTANDO',
        'iniciadoEm': '2026-09-02T10:00:00-03:00',
      },
    });

    expect(processo.statusExibido, StatusExecucao.executando);
    expect(processo.statusExibido.isTransitorio, isTrue);
    expect(processo.temAtividade, isTrue);
    expect(processo.ultimaExecucao?.finalizadoEm, isNull);
    expect(processo.ultimaExecucao?.duracaoMs, isNull);
  });

  test('execução com erro preserva a mensagem', () {
    final execucao = ExecucaoIntegracao.fromJson(const {
      'id': 'e3',
      'processo': 'funcionario-fpw',
      'status': 'ERRO',
      'mensagemErro': 'IllegalStateException: origem indisponivel',
    });

    expect(execucao.status.isErro, isTrue);
    expect(execucao.mensagemErro, contains('origem indisponivel'));
  });

  test('payload sem campos opcionais assume valores neutros', () {
    final execucao = ExecucaoIntegracao.fromJson(const {
      'id': 'e4',
      'processo': 'ponto',
      'status': 'CONCLUIDO',
    });

    expect(execucao.registrosLidos, 0);
    expect(execucao.registrosProcessados, 0);
    expect(execucao.iniciadoEm, isNull);
    expect(execucao.foiManual, isFalse);
  });
}
