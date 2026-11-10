import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/access/domain/entities/permission.dart';
import 'package:gjamobile/src/features/access/presentation/controllers/access_controller.dart';
import 'package:gjamobile/src/features/access/presentation/widgets/confirm_dialog.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/entities/produto.dart';
import 'package:gjamobile/src/features/rhprocesso/domain/rhprocesso_features.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/controllers/caracteristicas_controller.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/rhprocesso_format.dart';
import 'package:gjamobile/src/features/rhprocesso/presentation/widgets/rh_tabela.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela — RH Processo › Características de Produto (`/rh/caracteristicas`).
///
/// Associar (ou trocar) exige inclusão e remover exige exclusão na feature
/// `rhprocesso_caracteristicas`, como na API.
class CaracteristicasScreen extends StatefulWidget {
  const CaracteristicasScreen({super.key, this.controller, this.pode});

  /// Só nos testes; por padrão vêm do DI.
  final CaracteristicasController? controller;
  final bool Function(PermissionAction acao)? pode;

  @override
  State<CaracteristicasScreen> createState() => _CaracteristicasScreenState();
}

class _CaracteristicasScreenState extends State<CaracteristicasScreen> {
  late final _controller =
      widget.controller ?? AppInjector.get<CaracteristicasController>();
  late final TextEditingController _busca;

  bool _pode(PermissionAction acao) =>
      widget.pode?.call(acao) ??
      AppInjector.get<AccessController>()
          .can(RhprocessoFeatures.caracteristicas, acao);

  bool get _podeAssociar => _pode(PermissionAction.create);
  bool get _podeRemover => _pode(PermissionAction.delete);

  @override
  void initState() {
    super.initState();
    _busca = TextEditingController(text: _controller.busca.value);
    _controller.carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _associar(Produto produto) async {
    final grupos = await _controller.carregarGrupos();
    if (!mounted || grupos.isEmpty) return;
    final escolha = await showDialog<_Associacao>(
      context: context,
      builder: (_) => _AssociarDialog(
        produto: produto,
        grupos: grupos,
        subgrupos: _controller.subgrupos,
      ),
    );
    if (escolha == null) return;
    await _controller.associar(
      produto,
      grupo: escolha.grupo,
      subgrupo: escolha.subgrupo,
      fator: escolha.fator,
    );
  }

  Future<void> _remover(Produto produto) async {
    final ok = await confirmDialog(
      context,
      title: 'Remover característica',
      message: 'O produto ${produto.codigo} (${produto.descricao}) volta para a '
          'lista dos sem característica e passa a aparecer como "Produto ñ '
          'Associado" no resumo de volume.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (ok) await _controller.remover(produto);
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      appBar: AppTopBar(
        title: 'Características de Produto',
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(GjaIcons.refresh),
            onPressed: _controller.carregar,
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
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SignalBuilder(builder: (context) {
                  return SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Sem característica')),
                      ButtonSegment(value: true, label: Text('Com característica')),
                    ],
                    selected: {_controller.caracterizados.value},
                    onSelectionChanged: (s) =>
                        _controller.mostrarCaracterizados(s.first),
                  );
                }),
                SizedBox(
                  width: 280,
                  child: AppTextField(
                    hint: 'Buscar código, descrição ou grupo',
                    controller: _busca,
                    prefixIcon: const Icon(GjaIcons.search, size: 18),
                    onChanged: _controller.setBusca,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          SignalBuilder(builder: (context) {
            final todos = _controller.produtos.value;
            final visiveis = _controller.visiveis.value;
            final erro = _controller.erro.value;
            final caracterizados = _controller.caracterizados.value;
            if (_controller.carregando.value && todos.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: AppLoading(message: 'Carregando produtos…'),
              );
            }
            if (erro != null) {
              return AppErrorWidget(
                title: 'Não foi possível carregar os produtos',
                message: erro.message,
                onRetry: _controller.carregar,
              );
            }
            if (todos.isEmpty) {
              return AppEmptyState(
                icon: GjaIcons.product,
                title: caracterizados
                    ? 'Nenhum produto com característica'
                    : 'Todos os produtos ativos têm característica',
              );
            }
            final salvando = _controller.salvandoCodigo.value;
            final temAcao = caracterizados
                ? (_podeAssociar || _podeRemover)
                : _podeAssociar;
            return RhTabela<Produto>(
              titulo: '${visiveis.length} de ${todos.length} produto(s)',
              colunas: [
                const RhColuna('Código'),
                const RhColuna('Descrição'),
                const RhColuna('Fator CXU', numerica: true),
                if (caracterizados) ...[
                  const RhColuna('Grupo'),
                  const RhColuna('Subgrupo'),
                ],
                if (temAcao) const RhColuna(''),
              ],
              itens: visiveis,
              celulas: (p) => [
                Text(p.codigo),
                Text(p.descricao),
                Text(p.fator == null ? '—' : RhFormat.decimal(p.fator!)),
                if (caracterizados) ...[
                  Text(RhFormat.texto(p.grupo)),
                  Text(RhFormat.texto(p.subgrupo)),
                ],
                if (temAcao)
                  salvando == p.codigo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_podeAssociar)
                              IconButton(
                                tooltip: caracterizados
                                    ? 'Trocar característica'
                                    : 'Associar característica',
                                icon: Icon(
                                  caracterizados
                                      ? GjaIcons.edit
                                      : GjaIcons.chainLink,
                                  size: 18,
                                ),
                                onPressed: () => _associar(p),
                              ),
                            if (caracterizados && _podeRemover)
                              IconButton(
                                tooltip: 'Remover característica',
                                icon: const Icon(GjaIcons.brokenLink, size: 18),
                                onPressed: () => _remover(p),
                              ),
                          ],
                        ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

typedef _Associacao = ({String grupo, String subgrupo, double fator});

class _AssociarDialog extends StatefulWidget {
  const _AssociarDialog({
    required this.produto,
    required this.grupos,
    required this.subgrupos,
  });

  final Produto produto;
  final List<String> grupos;
  final Future<List<String>> Function(String grupo) subgrupos;

  @override
  State<_AssociarDialog> createState() => _AssociarDialogState();
}

class _AssociarDialogState extends State<_AssociarDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _fator;
  String? _grupo;
  String? _subgrupo;
  List<String> _opcoesSubgrupo = const [];
  bool _carregandoSubgrupos = false;

  @override
  void initState() {
    super.initState();
    final p = widget.produto;
    final fator = p.fator;
    _fator = TextEditingController(
      text: fator == null ? '' : fator.toString().replaceAll('.', ','),
    );
    if (p.grupo != null && widget.grupos.contains(p.grupo)) {
      _grupo = p.grupo;
      _subgrupo = p.subgrupo;
      _carregarSubgrupos(p.grupo!, manter: true);
    }
  }

  @override
  void dispose() {
    _fator.dispose();
    super.dispose();
  }

  Future<void> _carregarSubgrupos(String grupo, {bool manter = false}) async {
    setState(() {
      _carregandoSubgrupos = true;
      _opcoesSubgrupo = const [];
      if (!manter) _subgrupo = null;
    });
    final lista = await widget.subgrupos(grupo);
    if (!mounted || grupo != _grupo) return;
    setState(() {
      _carregandoSubgrupos = false;
      _opcoesSubgrupo = lista;
      if (_subgrupo != null && !lista.contains(_subgrupo)) _subgrupo = null;
    });
  }

  double? get _fatorNumerico =>
      double.tryParse(_fator.text.trim().replaceAll(',', '.'));

  void _salvar() {
    if (!(_form.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      grupo: _grupo!,
      subgrupo: _subgrupo!,
      fator: _fatorNumerico!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.produto;
    return AlertDialog(
      title: Text('Característica do produto ${p.codigo}'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(p.descricao, style: context.textTheme.bodyMedium),
              SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _grupo,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Grupo'),
                items: [
                  for (final g in widget.grupos)
                    DropdownMenuItem(value: g, child: Text(g)),
                ],
                validator: (v) => v == null ? 'Selecione o grupo' : null,
                onChanged: (g) {
                  if (g == null || g == _grupo) return;
                  _grupo = g;
                  _carregarSubgrupos(g);
                },
              ),
              SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: ValueKey('$_grupo-${_opcoesSubgrupo.length}'),
                initialValue: _subgrupo,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Subgrupo',
                  helperText: _carregandoSubgrupos ? 'Carregando…' : null,
                ),
                items: [
                  for (final s in _opcoesSubgrupo)
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                validator: (v) => v == null ? 'Selecione o subgrupo' : null,
                onChanged: (s) => _subgrupo = s,
              ),
              SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _fator,
                decoration: const InputDecoration(
                  labelText: 'Fator de conversão (CXU)',
                  helperText: 'Caixas unitárias por unidade vendida',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [DecimalInputFormatter(casas: 5)],
                validator: (_) {
                  final f = _fatorNumerico;
                  return f == null || f <= 0 ? 'Informe um fator maior que zero' : null;
                },
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
