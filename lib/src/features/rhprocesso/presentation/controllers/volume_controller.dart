import 'package:signals_flutter/signals_flutter.dart';

import 'package:gjamobile/src/features/rhprocesso/data/repositories/volume_repository.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/arquivo_gerado.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/consulta_volume.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/periodo.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/enums/visao_equipe.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/salvar_arquivo.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// Estado da tela Volume x NF (app-scoped): a última consulta continua na tela
/// ao voltar para ela.
///
/// O DANFE e a planilha são da consulta **processada**, não do que está
/// digitado: trocar a matrícula sem processar de novo não muda o arquivo.
class VolumeController {
  VolumeController({
    required VolumeRepository repository,
    EscolherDestino escolher = escolherDestino,
  })  : _repository = repository,
        _escolher = escolher;

  final VolumeRepository _repository;
  final EscolherDestino _escolher;

  final _periodos = signal<List<Periodo>>(const []);
  final _carregandoPeriodos = signal(false);
  final _periodo = signal<Periodo?>(null);
  final _visao = signal(VisaoEquipe.consultor);
  final _consulta = signal<ConsultaVolume?>(null);
  final _consultando = signal(false);
  final _erro = signal<AppFailure?>(null);
  final _gerandoDanfe = signal(false);
  final _exportando = signal(false);

  /// Parâmetros da consulta exibida: visão, matrícula e período.
  ({VisaoEquipe visao, String matricula, Periodo periodo})? _processada;

  ReadonlySignal<List<Periodo>> get periodos => _periodos;
  ReadonlySignal<bool> get carregandoPeriodos => _carregandoPeriodos;
  ReadonlySignal<Periodo?> get periodo => _periodo;
  ReadonlySignal<VisaoEquipe> get visao => _visao;
  ReadonlySignal<ConsultaVolume?> get consulta => _consulta;
  ReadonlySignal<bool> get consultando => _consultando;
  ReadonlySignal<AppFailure?> get erro => _erro;
  ReadonlySignal<bool> get gerandoDanfe => _gerandoDanfe;
  ReadonlySignal<bool> get exportando => _exportando;

  /// Carrega os períodos uma vez e seleciona o mais recente.
  Future<void> carregarPeriodos({bool forcar = false}) async {
    if (_periodos.value.isNotEmpty && !forcar) return;
    _carregandoPeriodos.value = true;
    final result = await _repository.periodos();
    _carregandoPeriodos.value = false;
    result.onSuccess((lista) {
      _periodos.value = lista;
      if (_periodo.value == null || !lista.contains(_periodo.value)) {
        _periodo.value = lista.isEmpty ? null : lista.first;
      }
    }).onFailure((failure) {
      _erro.value = failure;
      AppLogger.warning('VolumeController.carregarPeriodos: ${failure.message}');
    });
  }

  // ignore: use_setters_to_change_properties
  void selecionarPeriodo(Periodo? p) => _periodo.value = p;

  /// Trocar a visão descarta a consulta: as matrículas são de pessoas
  /// diferentes (consultor x supervisor).
  void selecionarVisao(VisaoEquipe v) {
    if (v == _visao.value) return;
    batch(() {
      _visao.value = v;
      _consulta.value = null;
      _erro.value = null;
    });
    _processada = null;
  }

  /// Valida a matrícula antes de chamar a API (só dígitos, até 10).
  static String? validarMatricula(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return 'Informe a matrícula.';
    if (!RegExp(r'^\d{1,10}$').hasMatch(t)) {
      return 'A matrícula tem só números (até 10 dígitos).';
    }
    return null;
  }

  Future<void> processar(String matricula) async {
    final periodo = _periodo.value;
    final invalida = validarMatricula(matricula);
    if (invalida != null || periodo == null) {
      _erro.value = ValidationFailure(invalida ?? 'Selecione o período.');
      return;
    }
    final mat = matricula.trim();
    final visao = _visao.value;

    batch(() {
      _consultando.value = true;
      _erro.value = null;
    });
    final result = await _repository.consultar(visao, mat, periodo);
    _consultando.value = false;

    result.onSuccess((c) {
      _consulta.value = c;
      _processada = (visao: visao, matricula: mat, periodo: periodo);
    }).onFailure((failure) {
      batch(() {
        _consulta.value = null;
        _erro.value = failure;
      });
      _processada = null;
    });
  }

  /// Há consulta processada para gerar DANFE e planilha.
  bool get podeGerar => _processada != null && _consulta.value != null;

  Future<void> gerarDanfe() => _gerar(
        _gerandoDanfe,
        'pdf',
        (p) => _repository.danfe(p.visao, p.matricula, p.periodo),
      );

  Future<void> exportarPlanilha() => _gerar(
        _exportando,
        'xlsx',
        (p) => _repository.planilha(p.visao, p.matricula, p.periodo),
      );

  Future<void> _gerar(
    Signal<bool> emAndamento,
    String extensao,
    AsyncAppResult<ArquivoGerado> Function(
            ({VisaoEquipe visao, String matricula, Periodo periodo}) p)
        chamada,
  ) async {
    final p = _processada;
    final consulta = _consulta.value;
    if (p == null || consulta == null || emAndamento.value) return;

    // Onde salvar é perguntado antes de gerar, em todas as plataformas.
    // Cancelou: não gera nada.
    final DestinoArquivo? destino;
    try {
      destino = await _escolher(
          nomeArquivoVolume(p.periodo.valor, consulta.equipe.nome, p.matricula, extensao));
    } catch (e) {
      AppLogger.warning('VolumeController: falha ao escolher onde salvar: $e');
      showGlobalToast(message: 'Não foi possível abrir o diálogo de salvar.', status: 'error');
      return;
    }
    if (destino == null) return;

    emAndamento.value = true;
    final result = await chamada(p);

    await result.fold((arquivo) async {
      try {
        if (!await destino!.gravar(arquivo)) {
          showGlobalToast(message: 'Arquivo não salvo.', status: 'info');
          return;
        }
        if (arquivo.aviso != null) {
          // O arquivo saiu, mas incompleto: o aviso fica até o usuário fechar.
          showGlobalToast(
            message: 'Arquivo ${arquivo.nome} salvo. ${arquivo.aviso}',
            status: 'warning',
            autoDismiss: false,
          );
        } else {
          showGlobalToast(message: 'Arquivo ${arquivo.nome} salvo.', status: 'success');
        }
      } catch (e) {
        AppLogger.warning('VolumeController: falha ao salvar ${arquivo.nome}: $e');
        showGlobalToast(message: 'Não foi possível salvar o arquivo.', status: 'error');
      }
    }, (failure) async {
      await destino!.descartar();
      showGlobalToast(message: failure.message, status: 'error');
    });
    emAndamento.value = false;
  }

  void dispose() {
    _periodos.dispose();
    _carregandoPeriodos.dispose();
    _periodo.dispose();
    _visao.dispose();
    _consulta.dispose();
    _consultando.dispose();
    _erro.dispose();
    _gerandoDanfe.dispose();
    _exportando.dispose();
  }
}
