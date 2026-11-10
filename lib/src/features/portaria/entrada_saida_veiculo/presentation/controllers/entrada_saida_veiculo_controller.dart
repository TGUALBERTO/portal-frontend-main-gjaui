import 'package:flutter/material.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/data/repositories/portaria_repository.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/entrada_saida_veiculo_mode.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/frota_veiculo.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/ocupante.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/tipo_veiculo.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/user_commav.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/veiculo.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/veiculo_retorno.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/veiculo_saida.dart';
import 'package:gjamobile/src/shared/enums/app_status.dart';
import 'package:gjamobile/src/shared/helpers/show_toast.dart';
import 'package:gjamobile/src/utils/utils.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Controller screen-scoped da tela de entrada/saída de veículos. Registrado
/// como factory (`i.add<T>`) no DI — a tela resolve uma instância nova e a
/// descarta no próprio `dispose()`.
class EntradaSaidaVeiculoController {
  EntradaSaidaVeiculoController({required PortariaRepository repository}) : _repository = repository;

  final PortariaRepository _repository;

  /// Formulário "código do veículo" (digitado ou preenchido pelo scanner).
  final codigoController = TextEditingController();

  /// Formulário "quilometragem do veículo" (digitado).
  final kmController = TextEditingController();

  /// Formulário "adicionar ocupante".
  final ocupanteFormKey = GlobalKey<FormState>();
  final matriculaController = TextEditingController();

  UserCommav? usuarioCommav;
  late EntradaSaidaVeiculoMode mode;

  late final Signal<AppStatus> _commavStatus = signal(AppStatus.initial);
  late final Signal<AppStatus> _frotasDiretoriaStatus = signal(AppStatus.initial);
  late final Signal<AppStatus> _frotasTerceiroStatus = signal(AppStatus.initial);
  late final Signal<List<FrotaVeiculo>> _frotasDiretoria = signal(const []);
  late final Signal<List<FrotaVeiculo>> _frotasTerceiro = signal(const []);
  late final Signal<AppStatus> _lookupStatus = signal(AppStatus.initial);
  late final Signal<Veiculo?> _veiculo = signal(null);
  late final Signal<VeiculoRetorno?> _veiculoRetorno = signal(null);
  late final Signal<VeiculoSaida?> _veiculoSaida = signal(null);

  late final Signal<AppFailure?> _lookupError = signal(null);
  late final Signal<List<Ocupante>> _ocupantes = signal(const []);
  late final Signal<AppStatus> _submitStatus = signal(AppStatus.initial);

  ReadonlySignal<AppStatus> get commavStatusSignal => _commavStatus;
  ReadonlySignal<AppStatus> get frotasDiretoriaStatusSignal => _frotasDiretoriaStatus;
  ReadonlySignal<AppStatus> get frotasTerceiroStatusSignal => _frotasTerceiroStatus;
  ReadonlySignal<List<FrotaVeiculo>> get frotasDiretoriaSignal => _frotasDiretoria;
  ReadonlySignal<List<FrotaVeiculo>> get frotasTerceiroSignal => _frotasTerceiro;
  ReadonlySignal<AppStatus> get lookupStatusSignal => _lookupStatus;
  ReadonlySignal<Veiculo?> get veiculoSignal => _veiculo;
  ReadonlySignal<VeiculoRetorno?> get veiculoRetornoSignal => _veiculoRetorno;
  ReadonlySignal<VeiculoSaida?> get veiculoSaidaSignal => _veiculoSaida;
  ReadonlySignal<AppFailure?> get lookupErrorSignal => _lookupError;
  ReadonlySignal<List<Ocupante>> get ocupantesSignal => _ocupantes;
  ReadonlySignal<AppStatus> get submitStatusSignal => _submitStatus;

  int _ultimaKmInvalida = 0;
  bool alterarQuilometragem = false;
  final Signal<bool> _solicitarConfirmacaoKm = signal(false);
  ReadonlySignal<bool> get solicitarConfirmacaoKmSignal => _solicitarConfirmacaoKm;

  Future<void> buscarUsuarioCommav({
    required BuildContext context,
    required String matricula,
    required EntradaSaidaVeiculoMode mode,
  }) async {
    if (_commavStatus.value == AppStatus.loading) return;

    _commavStatus.value = AppStatus.loading;

    final result = await _repository.getUserCommav(matricula);

    result.onSuccess((commav) {
      usuarioCommav = commav;
      this.mode = mode;
      _commavStatus.value = AppStatus.success;
      carregarFrotasDiretoria();
      carregarFrotasTerceiros();
    }).onFailure((failure) {
      _commavStatus.value = AppStatus.failure;
      if (context.mounted) showToast(context, message: 'Usuário COMMAV não foi encontrado', status: 'error');
    });
  }

  /// Frotas sem QR Code (diretoria etc.) da unidade do usuário COMMAV —
  /// carregadas logo após o [buscarUsuarioCommav] para a busca por placa.
  Future<void> carregarFrotasDiretoria() async {
    final commav = usuarioCommav;
    if (commav == null) return;
    if (_frotasDiretoriaStatus.value == AppStatus.loading) return;

    _frotasDiretoriaStatus.value = AppStatus.loading;

    final result = await _repository.getFrotas(unidade: commav.unidade, tipo: TipoVeiculo.diretoria, mode: mode);

    result.onSuccess((frota) {
      _frotasDiretoria.value = frota;
      _frotasDiretoriaStatus.value = AppStatus.success;
    }).onFailure((_) {
      _frotasDiretoriaStatus.value = AppStatus.failure;
    });
  }

  /// Frotas sem QR Code (diretoria etc.) da unidade do usuário COMMAV —
  /// carregadas logo após o [buscarUsuarioCommav] para a busca por placa.
  Future<void> carregarFrotasTerceiros() async {
    final commav = usuarioCommav;
    if (commav == null) return;
    if (_frotasTerceiroStatus.value == AppStatus.loading) return;

    _frotasTerceiroStatus.value = AppStatus.loading;

    final result = await _repository.getFrotas(unidade: commav.unidade, tipo: TipoVeiculo.terceiro, mode: mode);

    result.onSuccess((frotas) {
      _frotasTerceiro.value = frotas;
      _frotasTerceiroStatus.value = AppStatus.success;
    }).onFailure((_) {
      _frotasTerceiroStatus.value = AppStatus.failure;
    });
  }

  /// Seleção de um veículo de frota na busca por placa: preenche o código e
  /// segue o fluxo normal de lookup.
  Future<void> selecionarFrota({
    required BuildContext context,
    required FrotaVeiculo frota,
  }) {
    codigoController.text = frota.frota;
    return buscarVeiculo(context: context);
  }

  Future<void> buscarVeiculo({required BuildContext context}) async {
    if (_lookupStatus.value == AppStatus.loading) return;

    final codigo = codigoController.text.trim();
    if (codigo.isEmpty) {
      showToast(context, message: 'Informe ou escaneie o código do veículo', status: 'warning');
      return;
    }

    _lookupStatus.value = AppStatus.loading;
    _lookupError.value = null;
    _veiculoRetorno.value = null;

    if (mode == EntradaSaidaVeiculoMode.R) {
      final result = await _repository.getVeiculoRetorno(strpUnidade: usuarioCommav?.unidade ?? '', strpFrota: codigo);
      result.onSuccess((veiculoRetorno) {
        if (veiculoRetorno.frota.isEmpty) {
          _lookupError.value = const UnknownFailure('Veículo não encontrado');
          _lookupStatus.value = AppStatus.failure;
          if (context.mounted) showToast(context, message: 'Frota já retornada. Verificar no COMMAV', status: 'error');
          return;
        }
        _veiculoRetorno.value = veiculoRetorno;
        _lookupStatus.value = AppStatus.success;
      }).onFailure((failure) {
        _lookupError.value = failure;
        _lookupStatus.value = AppStatus.failure;
        if (context.mounted) showToast(context, message: failure.message, status: 'error');
      });
    } else {
      final result = await _repository.getVeiculoSaida(
        strpUnidade: usuarioCommav?.unidade ?? '',
        strpFrota: codigo,
      );
      result.onSuccess((veiculoSaida) {
        _veiculoSaida.value = veiculoSaida;
        _lookupStatus.value = AppStatus.success;
      }).onFailure((failure) {
        _lookupError.value = failure;
        _lookupStatus.value = AppStatus.failure;
        if (context.mounted) showToast(context, message: failure.message, status: 'error');
      });
    }
  }

  String? validateMatricula(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Obrigatório';
    if (int.tryParse(v) == null) return 'Somente números';
    return null;
  }

  Future<void> addOcupante({required BuildContext context}) async {
    if (!(ocupanteFormKey.currentState?.validate() ?? false)) return;

    final matricula = int.parse(matriculaController.text.trim());
    if (_ocupantes.value.any((o) => o.matricula == matricula)) {
      showToast(context, message: 'Matrícula já adicionada', status: 'warning');
      return;
    }

    //valida matricula
    /*
    final result = await _repository.getFuncionario(
      matricula: matricula,
    );
    result.onSuccess((funcionario) {
      _lookupStatus.value = AppStatus.success;

      _ocupantes.value = [..._ocupantes.value, Ocupante(matricula: funcionario.matricula)];
      matriculaController.clear();
    }).onFailure((failure) {
      _lookupError.value = failure;
      _lookupStatus.value = AppStatus.failure;
      if (context.mounted) showToast(context, message: failure.message, status: 'error');
    });
    */
  }

  void removeOcupante(Ocupante ocupante) {
    _ocupantes.value = _ocupantes.value.where((o) => o != ocupante).toList(growable: false);
  }

  Future<void> confirmar({
    required EntradaSaidaVeiculoMode mode,
    required BuildContext context,
  }) async {
    if (_submitStatus.value == AppStatus.loading) return;

    final veiculo = _veiculo.value;
    if (veiculo == null) return;
    if (_ocupantes.value.isEmpty) {
      showToast(context, message: 'Adicione ao menos um ocupante', status: 'warning');
      return;
    }

    _submitStatus.value = AppStatus.loading;
    final ocupantes = _ocupantes.value;
    final result = mode == EntradaSaidaVeiculoMode.R
        ? await _repository.createEntrada(codigo: veiculo.codigo, ocupantes: ocupantes)
        : await _repository.createSaida(codigo: veiculo.codigo, ocupantes: ocupantes);

    result.onSuccess((_) {
      _submitStatus.value = AppStatus.success;
      if (context.mounted) {
        showToast(
          context,
          message: mode == EntradaSaidaVeiculoMode.S ? 'Entrada registrada com sucesso' : 'Saída registrada com sucesso',
          status: 'success',
        );
      }
      resetForm();
    }).onFailure((failure) {
      _submitStatus.value = AppStatus.failure;
      if (context.mounted) showToast(context, message: failure.message, status: 'error');
    });
  }

  /// Reseta o formulário para o próximo veículo — fluxo repetitivo de
  /// portaria, o guarda processa vários veículos em sequência sem sair da
  /// tela.
  void resetForm() {
    codigoController.clear();
    matriculaController.clear();
    _veiculo.value = null;
    _lookupStatus.value = AppStatus.initial;
    _lookupError.value = null;
    _ocupantes.value = const [];
    _submitStatus.value = AppStatus.initial;
  }

  void dispose() {
    codigoController.dispose();
    matriculaController.dispose();
    _commavStatus.dispose();
    _frotasDiretoriaStatus.dispose();
    _frotasTerceiroStatus.dispose();
    _frotasDiretoria.dispose();
    _frotasTerceiro.dispose();
    _lookupStatus.dispose();
    _veiculo.dispose();
    _lookupError.dispose();
    _ocupantes.dispose();
    _submitStatus.dispose();
  }

  Future<bool> validarKilometragem({required BuildContext context}) async {
    final km = kmController.text.trim();
    final kmInformada = int.parse(kmController.text.trim());
    final kmAnterior = mode == EntradaSaidaVeiculoMode.R ? _veiculoRetorno.value?.quilometragem : _veiculoSaida.value?.quilometragem;

    if (km.isEmpty) {
      showToast(context, message: 'Informe a quilometragem do veículo', status: 'warning');
      return false;
    }
    if (int.tryParse(km) == null) {
      showToast(context, message: 'Quilometragem inválida', status: 'warning');
      return false;
    }

    if (mode == EntradaSaidaVeiculoMode.R) {
      if (kmInformada < kmAnterior!) {
        if (_ultimaKmInvalida == 0) {
          _ultimaKmInvalida = int.tryParse(kmController.text.trim()) ?? 0;
          kmController.clear();

          showToast(context, message: 'Quilometragem errada. Redigite.', status: 'warning');

          return false;
        }
      }

      if (_ultimaKmInvalida == (int.tryParse(kmController.text.trim()) ?? 0)) {
        final bool resposta = await _showPopupToConfirm(
          context: context,
          titulo: 'Quilometragem',
          mensagem: 'Alterar a Quilometragem?',
        );

        if (resposta == true) {
          return true;
        } else {
          _ultimaKmInvalida = 0;
          kmController.clear();
          return false;
        }

        // _solicitarConfirmacaoKm.value = true;
        // return false;
      }

      _ultimaKmInvalida = int.tryParse(kmController.text.trim()) ?? 0;
      kmController.clear();

      showToast(context, message: 'Quilometragem errada. Redigite', status: 'warning');

      return false;
    } else {
      if (_veiculoSaida.value?.quilometragem == int.parse(km)) {
        // Quilometragem é a mesma
        kmController.text = '';
      }
      return false;
    }
  }

  Future<bool> _showPopupToConfirm({required BuildContext context, required String titulo, required String mensagem}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(mensagem),
//Para mais de uma linha na mensagem                Text(mensagem),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Sim'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
