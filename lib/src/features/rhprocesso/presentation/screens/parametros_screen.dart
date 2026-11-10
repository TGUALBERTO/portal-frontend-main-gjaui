import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/permission.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/parametro.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/periodo.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/rhprocesso_features.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/parametros_controller.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela — RH Processo › Parâmetros Gerais (`/rh/parametros`).
///
/// Sem permissão de alteração em `rhprocesso_parametros`, a lista aparece sem
/// o botão de edição.
class ParametrosScreen extends StatefulWidget {
  const ParametrosScreen({super.key, this.controller, this.pode});

  /// Só nos testes; por padrão vêm do DI.
  final ParametrosController? controller;
  final bool Function(PermissionAction acao)? pode;

  @override
  State<ParametrosScreen> createState() => _ParametrosScreenState();
}

class _ParametrosScreenState extends State<ParametrosScreen> {
  late final _controller =
      widget.controller ?? AppInjector.get<ParametrosController>();

  bool _pode(PermissionAction acao) =>
      widget.pode?.call(acao) ??
      AppInjector.get<AccessController>().can(RhprocessoFeatures.parametros, acao);

  bool get _podeEditar => _pode(PermissionAction.update);

  @override
  void initState() {
    super.initState();
    _controller.carregar();
  }

  Future<void> _editar(Parametro p) async {
    final r = await showDialog<({String descricao, String valor})>(
      context: context,
      builder: (_) => _EditarParametroDialog(parametro: p),
    );
    if (r != null) {
      await _controller.alterar(p, descricao: r.descricao, valor: r.valor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      appBar: AppTopBar(
        title: 'Parâmetros Gerais',
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(GjaIcons.refresh),
            onPressed: _controller.carregar,
          ),
        ],
      ),
      body: SignalBuilder(builder: (context) {
        final lista = _controller.parametros.value;
        final erro = _controller.erro.value;
        if (_controller.carregando.value && lista.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: AppLoading(message: 'Carregando parâmetros…'),
          );
        }
        if (erro != null) {
          return AppErrorWidget(
            title: 'Não foi possível carregar os parâmetros',
            message: erro.message,
            onRetry: _controller.carregar,
          );
        }
        if (lista.isEmpty) {
          return const AppEmptyState(
            icon: GjaIcons.customize,
            title: 'Nenhum parâmetro cadastrado',
          );
        }
        final salvando = _controller.salvandoId.value;
        return Column(
          children: [
            for (final p in lista)
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  leading: CircleAvatar(child: Text('${p.id}')),
                  title: p.descricao,
                  subtitle: _valor(p),
                  trailing: !_podeEditar
                      ? null
                      : salvando == p.id
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              tooltip: 'Editar parâmetro',
                              icon: const Icon(GjaIcons.edit),
                              onPressed: () => _editar(p),
                            ),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        );
      }),
    );
  }

  static String _valor(Parametro p) => p.ehPeriodo
      ? 'Valor: ${p.valor} (${Periodo('${p.valor}').rotulo})'
      : 'Valor: ${p.valor} ${p.unidade}';
}

class _EditarParametroDialog extends StatefulWidget {
  const _EditarParametroDialog({required this.parametro});

  final Parametro parametro;

  @override
  State<_EditarParametroDialog> createState() => _EditarParametroDialogState();
}

class _EditarParametroDialogState extends State<_EditarParametroDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _descricao;
  late final TextEditingController _valor;

  @override
  void initState() {
    super.initState();
    _descricao = TextEditingController(text: widget.parametro.descricao);
    _valor = TextEditingController(text: '${widget.parametro.valor}');
  }

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!(_form.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((descricao: _descricao.text, valor: _valor.text));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.parametro;
    return AlertDialog(
      title: Text('Parâmetro ${p.id}'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descricao,
                decoration: const InputDecoration(labelText: 'Descrição'),
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe a descrição' : null,
              ),
              SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _valor,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  helperText: p.ehPeriodo
                      ? 'Período no formato yyyymm (ex.: 202501)'
                      : 'Número de ${p.id == 4 ? 'dias' : 'anos'} (inteiro, 0 ou mais)',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(p.ehPeriodo ? 6 : 3),
                ],
                validator: (v) => p.validar(v ?? ''),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AppButton(label: 'Salvar', height: ButtonSize.small, onPressed: _salvar),
      ],
    );
  }
}
