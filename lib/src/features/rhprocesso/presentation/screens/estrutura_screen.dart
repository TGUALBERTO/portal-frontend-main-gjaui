import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/permission.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/confirm_dialog.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/estrutura_rota.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/periodo.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/rhprocesso_features.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/estrutura_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/rhprocesso_format.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/widgets/rh_tabela.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela — RH Processo › Estrutura Comercial (`/rh/estrutura`).
///
/// Período do Workflow, importação das rotas que faltam e manutenção da
/// hierarquia de cada rota. "Importar" exige inclusão e "Editar" exige
/// alteração na feature `rhprocesso_estrutura`.
class EstruturaScreen extends StatefulWidget {
  const EstruturaScreen({super.key, this.controller, this.pode});

  /// Só nos testes; por padrão vêm do DI.
  final EstruturaController? controller;
  final bool Function(PermissionAction acao)? pode;

  @override
  State<EstruturaScreen> createState() => _EstruturaScreenState();
}

class _EstruturaScreenState extends State<EstruturaScreen> {
  late final _controller =
      widget.controller ?? AppInjector.get<EstruturaController>();
  late final TextEditingController _busca;

  bool _pode(PermissionAction acao) =>
      widget.pode?.call(acao) ??
      AppInjector.get<AccessController>().can(RhprocessoFeatures.estrutura, acao);

  bool get _podeImportar => _pode(PermissionAction.create);
  bool get _podeEditar => _pode(PermissionAction.update);

  @override
  void initState() {
    super.initState();
    _busca = TextEditingController(text: _controller.busca.value);
    _controller.iniciar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _importar() async {
    final p = _controller.periodo.value;
    if (p == null) return;
    final ok = await confirmDialog(
      context,
      title: 'Importar estrutura',
      message: 'Incluir em ${p.rotulo} as rotas do Workflow que ainda não '
          'estão no RH Processo? As rotas existentes não são alteradas.',
      confirmLabel: 'Importar',
    );
    if (ok) await _controller.importar();
  }

  Future<void> _editar(EstruturaRota rota) async {
    final nova = await showDialog<EstruturaRota>(
      context: context,
      builder: (_) => _EditarRotaDialog(rota: rota),
    );
    if (nova != null) await _controller.alterar(nova);
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      appBar: AppTopBar(
        title: 'Estrutura Comercial',
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(GjaIcons.refresh),
            onPressed: _controller.listar,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 220,
                  child: SignalBuilder(builder: (context) {
                    final periodos = _controller.periodos.value;
                    final atual = _controller.periodo.value;
                    return DropdownButtonFormField<Periodo>(
                      key: ValueKey('${periodos.length}-${atual?.valor}'),
                      initialValue: atual,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Período (Workflow)'),
                      items: [
                        for (final p in periodos)
                          DropdownMenuItem(value: p, child: Text(p.rotulo)),
                      ],
                      onChanged: _controller.selecionarPeriodo,
                    );
                  }),
                ),
                SizedBox(
                  width: 280,
                  child: AppTextField(
                    hint: 'Buscar rota, unidade ou nome',
                    controller: _busca,
                    prefixIcon: const Icon(GjaIcons.search, size: 18),
                    onChanged: _controller.setBusca,
                  ),
                ),
                if (_podeImportar)
                  SignalBuilder(builder: (context) {
                    final importando = _controller.importando.value;
                    return AppButton(
                      label: 'Importar do Workflow',
                      prefixIcon: const Icon(GjaIcons.download, size: 18),
                      isLoading: importando,
                      onPressed: importando || _controller.periodo.value == null
                          ? null
                          : _importar,
                    );
                  }),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          SignalBuilder(builder: (context) {
            final rotas = _controller.rotas.value;
            final visiveis = _controller.visiveis.value;
            final erro = _controller.erro.value;
            if (_controller.carregando.value && rotas.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: AppLoading(message: 'Carregando estrutura…'),
              );
            }
            if (erro != null) {
              return AppErrorWidget(
                title: 'Não foi possível carregar a estrutura',
                message: erro.message,
                onRetry: _controller.iniciar,
              );
            }
            if (_controller.periodos.value.isEmpty) {
              return const AppEmptyState(
                icon: GjaIcons.orgChart,
                title: 'Nenhum período no Workflow',
              );
            }
            if (rotas.isEmpty) {
              return AppEmptyState(
                icon: GjaIcons.orgChart,
                title: 'Período sem estrutura',
                subtitle: _podeImportar
                    ? 'Use "Importar do Workflow" para trazer as rotas.'
                    : 'Nenhuma rota cadastrada neste período.',
              );
            }
            final salvando = _controller.salvandoChave.value;
            return RhTabela<EstruturaRota>(
              titulo: '${visiveis.length} de ${rotas.length} rota(s)',
              paginacaoNoTopo: true,
              colunas: [
                const RhColuna('Unidade'),
                const RhColuna('Rota'),
                const RhColuna('Consultor'),
                const RhColuna('Supervisor'),
                const RhColuna('Gerente de vendas'),
                const RhColuna('Gerente comercial'),
                if (_podeEditar) const RhColuna(''),
              ],
              itens: visiveis,
              celulas: (r) => [
                Text(r.unidade),
                Text(r.rota),
                Text(_pessoa(r.matriculaConsultor, r.nomeConsultor)),
                Text(_pessoa(r.matriculaSupervisor, r.nomeSupervisor)),
                Text(_pessoa(r.matriculaGerenteVendas, r.nomeGerenteVendas)),
                Text(_pessoa(r.matriculaGerenteComercial, r.nomeGerenteComercial)),
                if (_podeEditar)
                  salvando == r.chave
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: 'Editar rota',
                          icon: const Icon(GjaIcons.edit, size: 18),
                          onPressed: () => _editar(r),
                        ),
              ],
            );
          }),
        ],
      ),
    );
  }

  static String _pessoa(String? matricula, String? nome) {
    final m = matricula?.trim() ?? '';
    final n = nome?.trim() ?? '';
    if (m.isEmpty && n.isEmpty) return '—';
    if (m.isEmpty) return n;
    if (n.isEmpty) return m;
    return '$m · $n';
  }
}

/// Diálogo de edição da hierarquia de uma rota. Devolve a rota alterada, ou
/// `null` se cancelado.
class _EditarRotaDialog extends StatefulWidget {
  const _EditarRotaDialog({required this.rota});

  final EstruturaRota rota;

  @override
  State<_EditarRotaDialog> createState() => _EditarRotaDialogState();
}

class _EditarRotaDialogState extends State<_EditarRotaDialog> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _campos;

  @override
  void initState() {
    super.initState();
    final r = widget.rota;
    _campos = {
      'matriculaConsultor': TextEditingController(text: r.matriculaConsultor),
      'nomeConsultor': TextEditingController(text: r.nomeConsultor),
      'matriculaSupervisor': TextEditingController(text: r.matriculaSupervisor),
      'nomeSupervisor': TextEditingController(text: r.nomeSupervisor),
      'matriculaGerenteVendas':
          TextEditingController(text: r.matriculaGerenteVendas),
      'nomeGerenteVendas': TextEditingController(text: r.nomeGerenteVendas),
      'matriculaGerenteComercial':
          TextEditingController(text: r.matriculaGerenteComercial),
      'nomeGerenteComercial':
          TextEditingController(text: r.nomeGerenteComercial),
    };
  }

  @override
  void dispose() {
    for (final c in _campos.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _v(String campo) => _campos[campo]!.text;

  void _salvar() {
    if (!(_form.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(widget.rota.copyWith(
      matriculaConsultor: _v('matriculaConsultor'),
      nomeConsultor: _v('nomeConsultor'),
      matriculaSupervisor: _v('matriculaSupervisor'),
      nomeSupervisor: _v('nomeSupervisor'),
      matriculaGerenteVendas: _v('matriculaGerenteVendas'),
      nomeGerenteVendas: _v('nomeGerenteVendas'),
      matriculaGerenteComercial: _v('matriculaGerenteComercial'),
      nomeGerenteComercial: _v('nomeGerenteComercial'),
    ));
  }

  static String? _obrigatorio(String? v) =>
      v == null || v.trim().isEmpty ? 'Obrigatório' : null;

  static String? _matriculaOpcional(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    return RegExp(r'^\d{1,10}$').hasMatch(t) ? null : 'Só números (até 10)';
  }

  Widget _linha(String titulo, String mat, String nome, {bool obrigatorio = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: TextFormField(
              controller: _campos[mat],
              decoration: InputDecoration(labelText: 'Matrícula $titulo'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: obrigatorio
                  ? (v) => _obrigatorio(v) ?? _matriculaOpcional(v)
                  : _matriculaOpcional,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              controller: _campos[nome],
              decoration: InputDecoration(labelText: 'Nome $titulo'),
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
              validator: obrigatorio ? _obrigatorio : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rota;
    return AlertDialog(
      title: Text('Rota ${r.rota} · unidade ${r.unidade}'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'Período ${Periodo(r.periodo).rotulo}. Deixe vazio o gestor '
                    'que a rota não tem.',
                    style: context.textTheme.bodySmall,
                  ),
                ),
                _linha('do consultor', 'matriculaConsultor', 'nomeConsultor',
                    obrigatorio: true),
                _linha('do supervisor', 'matriculaSupervisor', 'nomeSupervisor'),
                _linha('do gerente de vendas', 'matriculaGerenteVendas',
                    'nomeGerenteVendas'),
                _linha('do gerente comercial', 'matriculaGerenteComercial',
                    'nomeGerenteComercial'),
                Text(
                  'Supervisão: ${RhFormat.texto(r.descricaoSupervisao)} · '
                  'Gerência: ${RhFormat.texto(r.descricaoGerenciaVendas)}',
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AppButton(
          label: 'Salvar',
          height: ButtonSize.small,
          onPressed: _salvar,
        ),
      ],
    );
  }
}
