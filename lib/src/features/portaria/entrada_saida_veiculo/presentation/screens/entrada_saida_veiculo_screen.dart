import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/entrada_saida_veiculo_mode.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/frota_veiculo.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/domain/entities/ocupante.dart';
import 'package:gjamobile/src/features/portaria/entrada_saida_veiculo/presentation/controllers/entrada_saida_veiculo_controller.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gjamobile/src/shared/wrappers/base_state_wrapper.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

enum _TipoVeiculo { proprio, terceiros, diretoria }

extension on _TipoVeiculo {
  String get label => switch (this) {
        _TipoVeiculo.proprio => 'Próprio',
        _TipoVeiculo.terceiros => 'Terceiros',
        _TipoVeiculo.diretoria => 'Diretoria',
      };

  IconData get icon => switch (this) {
        _TipoVeiculo.proprio => GjaIcons.carRental,
        _TipoVeiculo.terceiros => GjaIcons.shippingStatus,
        _TipoVeiculo.diretoria => GjaIcons.suitcase,
      };
}

class EntradaSaidaVeiculoScreen extends StatefulWidget {
  const EntradaSaidaVeiculoScreen({super.key, required this.mode, required this.matricula});

  final EntradaSaidaVeiculoMode mode;
  final String matricula;

  @override
  State<EntradaSaidaVeiculoScreen> createState() => _EntradaSaidaVeiculoScreenState();
}

class _EntradaSaidaVeiculoScreenState extends BaseState<EntradaSaidaVeiculoScreen, EntradaSaidaVeiculoController> {
  bool get _isEntrada => widget.mode == EntradaSaidaVeiculoMode.R;

  _TipoVeiculo _tipoVeiculo = _TipoVeiculo.proprio;

  @override
  void initState() {
    super.initState();
    controller.buscarUsuarioCommav(context: context, matricula: widget.matricula, mode: widget.mode);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _onScan() async {
    final scanned =
        await showQrScannerScreen(context, title: 'Ler QR Code do veículo');
    if (scanned == null || !mounted) return;
    controller.codigoController.text = scanned;
    await controller.buscarVeiculo(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      formWidth: true,
      appBar: AppTopBar(
        title: _isEntrada ? 'Entrada de Veículo' : 'Saída de Veículo',
      ),
      body: SignalBuilder(builder: (context) {
        final commavStatus = controller.commavStatusSignal.value;
        return switch (commavStatus) {
          AppStatus.initial || AppStatus.loading => const AppLoading(message: 'Verificando acesso...'),
          AppStatus.failure => AppErrorWidget(
              message: 'Usuário COMMAV não foi encontrado.',
              onRetry: () => controller.buscarUsuarioCommav(context: context, matricula: widget.matricula, mode: widget.mode),
            ),
          AppStatus.success => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTipoVeiculoSection(context), //BLOCO TIPO DE VEICULO
                SizedBox(height: AppSpacing.lg),
                _buildCodigoSection(context), //CODIGO DO VEICULO
                SizedBox(height: AppSpacing.lg),
                _buildVeiculoSection(context),
                SizedBox(height: AppSpacing.lg),
                _buildInformacoesAdicionaisSection(context), //CODIGO DO VEICULO
                SizedBox(height: AppSpacing.lg),
                _buildOcupantesSection(context),
                SizedBox(height: AppSpacing.xl),
                _buildConfirmarButton(context),
              ],
            ),
        };
      }),
    );
  }

  Widget _buildTipoVeiculoSection(BuildContext context) {
    return AppCard(
      title: 'Tipo de veículo',
      child: SegmentedButton<_TipoVeiculo>(
        segments: [
          for (final tipo in _TipoVeiculo.values)
            ButtonSegment(
              value: tipo,
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(tipo.label, maxLines: 1, softWrap: false),
              ),
              icon: Icon(tipo.icon),
            ),
        ],
        selected: {_tipoVeiculo},
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        style: SegmentedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        onSelectionChanged: (selection) => setState(() => _tipoVeiculo = selection.first),
      ),
    );
  }

  Widget _buildCodigoSection(BuildContext context) {
    final isDiretoria = _tipoVeiculo == _TipoVeiculo.diretoria;
    final isTerceiro = _tipoVeiculo == _TipoVeiculo.terceiros;
    final isPropio = _tipoVeiculo == _TipoVeiculo.proprio;
    return AppCard(
      title: isDiretoria
          ? 'Veículo da diretoria'
          : isTerceiro
              ? 'Veículo terceiros'
              : 'Código do veículo',
      child: isPropio == false
          ? _buildPlacaSearchField(context)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Código',
                  hint: 'Digite ou escaneie o código do veículo',
                  controller: controller.codigoController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onFieldSubmitted: (_) => controller.buscarVeiculo(context: context),
                ),
                SizedBox(height: AppSpacing.md),
                SignalBuilder(builder: (context) {
                  final loading = controller.lookupStatusSignal.value == AppStatus.loading;
                  return Row(
                    children: [
                      if (PlatformInfo.isMobile) ...[
                        Expanded(
                          child: AppButton(
                            label: 'Ler QR Code',
                            variant: ButtonVariant.outline,
                            prefixIcon: const Icon(GjaIcons.qrCode),
                            onPressed: loading ? null : _onScan,
                          ),
                        ),
                        SizedBox(width: AppSpacing.ms),
                      ],
                      Expanded(
                        child: AppButton(
                          label: 'Buscar',
                          isLoading: loading,
                          onPressed: () => controller.buscarVeiculo(context: context),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildInformacoesAdicionaisCard(BuildContext context) {
    return AppCard(
      title: 'Informações adicionais',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'KM do Veículo',
            hint: 'Digite a Quilometragem do veículo',
            controller: controller.kmController,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => controller.validarKilometragem(context: context),
          ),
          SizedBox(height: AppSpacing.md),
          SignalBuilder(builder: (context) {
            final loading = controller.lookupStatusSignal.value == AppStatus.loading;
            return Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Validar KM',
                    isLoading: loading,
                    onPressed: () => controller.validarKilometragem(context: context),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  static String _normalizePlaca(String value) => value.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  /// Busca por placa para veículos de frota (diretoria) — sem QR Code, o
  /// guarda localiza o veículo pela placa e a seleção dispara o lookup normal.
  Widget _buildPlacaSearchField(BuildContext context) {
    final isDiretoria = _tipoVeiculo == _TipoVeiculo.diretoria;
    return SignalBuilder(builder: (context) {
      final status = isDiretoria ? controller.frotasDiretoriaSignal.value : controller.frotasTerceiroStatusSignal.value;
      if (status == AppStatus.failure) {
        return AppErrorWidget(
          message: 'Não foi possível carregar os veículos.',
          onRetry: () => isDiretoria ? controller.carregarFrotasDiretoria() : controller.carregarFrotasTerceiros(),
        );
      }

      final frotas = isDiretoria ? controller.frotasDiretoriaSignal.value : controller.frotasTerceiroSignal.value;
      final loading = status != AppStatus.success;
      return LayoutBuilder(builder: (context, constraints) {
        return Autocomplete<FrotaVeiculo>(
          optionsBuilder: (textEditingValue) {
            final query = _normalizePlaca(textEditingValue.text);
            if (query.isEmpty) return frotas;
            return frotas.where((f) => _normalizePlaca(f.placa).contains(query) || f.frota.contains(query));
          },
          displayStringForOption: (f) => f.placa,
          onSelected: (f) => controller.selecionarFrota(context: context, frota: f),
          fieldViewBuilder: (context, textController, focusNode, _) {
            return AppTextField(
              label: 'Placa',
              hint: loading ? 'Carregando veículos...' : 'Pesquise pela placa do veículo',
              controller: textController,
              focusNode: focusNode,
              autofocus: true,
              prefixIcon: const Icon(GjaIcons.search),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: AppBorders.sm,
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 240,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final frota = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        leading: const Icon(GjaIcons.carRental),
                        title: Text(frota.placa),
                        subtitle: Text('Frota ${frota.frota}'),
                        onTap: () => onSelected(frota),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      });
    });
  }

  Widget _buildInformacoesAdicionaisSection(BuildContext context) {
    return SignalBuilder(builder: (context) {
      final status = controller.lookupStatusSignal.value;
      return switch (status) {
        AppStatus.initial => const SizedBox.shrink(),
        AppStatus.loading => const AppLoading(message: 'Validando KM...'),
        AppStatus.failure => AppErrorWidget(
            message: controller.lookupErrorSignal.value?.message,
            onRetry: () => controller.buscarVeiculo(context: context),
          ),
        AppStatus.success => _buildInformacoesAdicionaisCard(context),
      };
    });
  }

  Widget _buildVeiculoSection(BuildContext context) {
    return SignalBuilder(builder: (context) {
      final status = controller.lookupStatusSignal.value;
      return switch (status) {
        AppStatus.initial => const SizedBox.shrink(),
        AppStatus.loading => const AppLoading(message: 'Buscando veículo...'),
        AppStatus.failure => AppErrorWidget(
            message: controller.lookupErrorSignal.value?.message,
            onRetry: () => controller.buscarVeiculo(context: context),
          ),
        AppStatus.success => widget.mode == EntradaSaidaVeiculoMode.R ? _buildVeiculoRetornoCard(context) : _buildVeiculoSaidaCard(context),
      };
    });
  }

  Widget _buildVeiculoRetornoCard(BuildContext context) {
    final veiculo = controller.veiculoRetornoSignal.value;
    if (veiculo == null) return const SizedBox.shrink();
    return AppCard(
      showShadow: true,
      title: 'Dados do veículo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileInfoTile(icon: GjaIcons.numberSign, label: 'Código', value: veiculo.frota),
          ProfileInfoTile(icon: GjaIcons.carRental, label: 'Placa', value: veiculo.placa),
          ProfileInfoTile(icon: GjaIcons.information, label: 'Motorista', value: veiculo.nomeMotorista),
        ],
      ),
    );
  }

  Widget _buildVeiculoSaidaCard(BuildContext context) {
    final veiculo = controller.veiculoSaidaSignal.value;
    if (veiculo == null) return const SizedBox.shrink();
    return AppCard(
      showShadow: true,
      title: 'Dados do veículo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileInfoTile(icon: GjaIcons.numberSign, label: 'Código', value: veiculo.frota),
          ProfileInfoTile(icon: GjaIcons.carRental, label: 'Placa', value: veiculo.placa),
          ProfileInfoTile(icon: GjaIcons.information, label: 'Motorista', value: veiculo.nomeMotorista),
        ],
      ),
    );
  }

  Widget _buildOcupantesSection(BuildContext context) {
    return SignalBuilder(builder: (context) {
      if (controller.veiculoSaidaSignal.value == null && controller.veiculoRetornoSignal.value == null) return const SizedBox.shrink();

      return AppCard(
        title: 'Ocupantes',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: controller.ocupanteFormKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Matrícula do funcionário',
                      controller: controller.matriculaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: controller.validateMatricula,
                      onFieldSubmitted: (_) => controller.addOcupante(context: context),
                    ),
                  ),
                  SizedBox(width: AppSpacing.ms),
                  AppButton(
                    label: 'Adicionar',
                    onPressed: () => controller.addOcupante(context: context),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),
            SignalBuilder(builder: (context) {
              final ocupantes = controller.ocupantesSignal.value;
              if (ocupantes.isEmpty) {
                return Text(
                  'Nenhum ocupante adicionado.',
                  style: context.textTheme.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                );
              }
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final Ocupante ocupante in ocupantes)
                    InputChip(
                      label: Text('Mat. ${ocupante.matricula}', style: context.textTheme.bodyMedium),
                      onDeleted: () => controller.removeOcupante(ocupante),
                    ),
                ],
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildConfirmarButton(BuildContext context) {
    return SignalBuilder(builder: (context) {
      final hasVeiculo = controller.veiculoSignal.value != null;
      final hasOcupantes = controller.ocupantesSignal.value.isNotEmpty;
      final submitting = controller.submitStatusSignal.value == AppStatus.loading;

      return AppButton(
        label: _isEntrada ? 'Confirmar Entrada' : 'Confirmar Saída',
        isFullWidth: true,
        isLoading: submitting,
        onPressed: hasVeiculo && hasOcupantes && !submitting ? () => controller.confirmar(mode: widget.mode, context: context) : null,
      );
    });
  }
}
