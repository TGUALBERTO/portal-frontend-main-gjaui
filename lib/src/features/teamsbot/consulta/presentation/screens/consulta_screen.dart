import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/auth/presentation/controllers/session_controller.dart';
import 'package:gjamobile/src/features/teamsbot/consulta/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/consulta/presentation/controllers/consulta_controller.dart';
import 'package:gjamobile/src/features/teamsbot/consulta/presentation/widgets/fonte_card.dart';
import 'package:gjamobile/src/features/teamsbot/shared/formatters.dart';
import 'package:gjamobile/src/features/teamsbot/shared/widgets/empresa_field.dart';
import 'package:gjamobile/src/features/teamsbot/shared/widgets/markdown_view.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela — Consulta RAG (`/teamsbot/consultar`). A tela principal de valor.
///
/// Em telas largas a resposta é o foco (coluna principal) e as fontes ficam
/// num painel lateral; em telas estreitas tudo empilha. Antes da primeira
/// pergunta, sugestões clicáveis ajudam a começar.
class ConsultaScreen extends StatefulWidget {
  const ConsultaScreen({super.key});

  @override
  State<ConsultaScreen> createState() => _ConsultaScreenState();
}

class _ConsultaScreenState extends State<ConsultaScreen> {
  late final ConsultaController _controller;

  final _pergunta = TextEditingController();
  final _empresa = TextEditingController();
  final _participante = TextEditingController();
  DateTime? _dataInicio;
  DateTime? _dataFim;

  /// Pergunta efetivamente enviada — exibida no cabeçalho da resposta.
  String? _ultimaPergunta;

  @override
  void initState() {
    super.initState();
    _controller = AppInjector.get<ConsultaController>();
  }

  @override
  void dispose() {
    _pergunta.dispose();
    _empresa.dispose();
    _participante.dispose();
    super.dispose();
  }

  void _consultar() {
    final pergunta = _pergunta.text.trim();
    if (pergunta.isEmpty) {
      context.showTypedSnackBar('Digite uma pergunta.',
          type: SnackBarType.warning);
      return;
    }
    context.hideKeyboard();
    setState(() => _ultimaPergunta = pergunta);
    _controller.consultar(
      pergunta: pergunta,
      // Amarra a consulta ao usuário logado — é o que alimenta "Minhas consultas".
      usuarioId: AppInjector.get<SessionController>().user?.id ?? '',
      filtros: ConsultaFiltros(
        empresa: _empresa.text.trim(),
        participante: _participante.text.trim(),
        dataInicio: _dataInicio,
        dataFim: _dataFim,
      ),
    );
  }

  void _usarSugestao(String pergunta) {
    _pergunta.text = pergunta;
    _consultar();
  }

  Future<void> _copiarResposta() async {
    final texto = _controller.resposta.value?.resposta ?? '';
    if (texto.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: texto));
    showGlobalToast(message: 'Resposta copiada.', status: 'success');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultar ATAs'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Minhas consultas',
            icon: const Icon(GjaIcons.history),
            onPressed: () => context.push(AppRoutes.teamsbotConsultaHistorico),
          ),
        ],
      ),
      body: AppResponsiveContainer(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          return SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroBusca(
                  pergunta: _pergunta,
                  empresa: _empresa,
                  participante: _participante,
                  dataInicio: _dataInicio,
                  dataFim: _dataFim,
                  onPickInicio: (d) => setState(() => _dataInicio = d),
                  onPickFim: (d) => setState(() => _dataFim = d),
                  onConsultar: _consultar,
                  isLoading: _controller.isLoading,
                ),
                SizedBox(height: AppSpacing.lg),
                SignalBuilder(builder: (context) {
                  final isLoading = _controller.isLoading.value;
                  final hasSearched = _controller.hasSearched.value;
                  final error = _controller.error.value;
                  final resposta = _controller.resposta.value;

                  if (isLoading) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: const AppLoading(
                          message:
                              'Consultando as ATAs e sintetizando a resposta…'),
                    );
                  }
                  if (hasSearched && error != null) {
                    return AppErrorWidget(
                      title: 'Não foi possível concluir a consulta',
                      message: error.message,
                      onRetry: _consultar,
                    );
                  }
                  if (!hasSearched || resposta == null) {
                    return _Sugestoes(onPick: _usarSugestao);
                  }
                  return _Resultado(
                    wide: wide,
                    resposta: resposta,
                    pergunta: _ultimaPergunta,
                    onCopiar: _copiarResposta,
                  );
                }),
                SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Busca (pergunta + filtros)
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBusca extends StatelessWidget {
  const _HeroBusca({
    required this.pergunta,
    required this.empresa,
    required this.participante,
    required this.dataInicio,
    required this.dataFim,
    required this.onPickInicio,
    required this.onPickFim,
    required this.onConsultar,
    required this.isLoading,
  });

  final TextEditingController pergunta;
  final TextEditingController empresa;
  final TextEditingController participante;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final ValueChanged<DateTime?> onPickInicio;
  final ValueChanged<DateTime?> onPickFim;
  final VoidCallback onConsultar;
  final ReadonlySignal<bool> isLoading;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;

        final campoPergunta = AppTextField(
          label: 'Pergunta',
          hint: 'Ex.: Qual foi a decisão sobre o orçamento de nuvem?',
          controller: pergunta,
          minLines: 1,
          maxLines: 3,
          prefixIcon: const Icon(GjaIcons.search, size: 20),
          textInputAction: TextInputAction.search,
          onFieldSubmitted: (_) => onConsultar(),
        );

        // FilledButton com tamanho fixo: o AppButton escala com o screenutil
        // e ficava gigante em monitores grandes.
        final botao = SignalBuilder(builder: (context) {
          final loading = isLoading.value;
          final button = FilledButton.icon(
            onPressed: loading ? null : onConsultar,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(GjaIcons.ai, size: 18),
            label: const Text('Consultar'),
          );
          return narrow
              ? SizedBox(width: double.infinity, child: button)
              : button;
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (narrow) ...[
              campoPergunta,
              SizedBox(height: AppSpacing.sm),
              botao,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: campoPergunta),
                  SizedBox(width: AppSpacing.sm),
                  botao,
                ],
              ),
            SizedBox(height: AppSpacing.sm),
            _FiltrosTile(
              empresa: empresa,
              participante: participante,
              dataInicio: dataInicio,
              dataFim: dataFim,
              onPickInicio: onPickInicio,
              onPickFim: onPickFim,
            ),
            // Chips dos filtros preenchidos (visíveis mesmo com o tile fechado).
            ListenableBuilder(
              listenable: Listenable.merge([empresa, participante]),
              builder: (context, _) {
                final chips = <Widget>[
                  if (empresa.text.trim().isNotEmpty)
                    _FilterChip(
                        label: 'Empresa: ${empresa.text.trim()}',
                        onRemove: empresa.clear),
                  if (participante.text.trim().isNotEmpty)
                    _FilterChip(
                        label: 'Participante: ${participante.text.trim()}',
                        onRemove: participante.clear),
                  if (dataInicio != null)
                    _FilterChip(
                        label: 'De: ${AtaFormat.data(dataInicio)}',
                        onRemove: () => onPickInicio(null)),
                  if (dataFim != null)
                    _FilterChip(
                        label: 'Até: ${AtaFormat.data(dataFim)}',
                        onRemove: () => onPickFim(null)),
                ];
                if (chips.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: chips,
                  ),
                );
              },
            ),
          ],
        );
      }),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    // Cores explícitas do scheme para funcionar no tema escuro.
    return Chip(
      label: Text(label),
      labelStyle: context.textTheme.bodySmall?.copyWith(color: cs.onSurface),
      backgroundColor: cs.surfaceContainerHigh,
      side: BorderSide(color: cs.outlineVariant),
      onDeleted: onRemove,
      deleteIcon: const Icon(GjaIcons.decline, size: 16),
      deleteIconColor: cs.onSurfaceVariant,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado inicial (sugestões)
// ─────────────────────────────────────────────────────────────────────────────

class _Sugestoes extends StatelessWidget {
  const _Sugestoes({required this.onPick});

  final ValueChanged<String> onPick;

  static const _exemplos = [
    'Quais foram as principais decisões da última semana?',
    'Quais pendências estão em aberto e quem são os responsáveis?',
    'O que foi definido sobre orçamento?',
    'Há riscos ou pontos de atenção registrados nas últimas reuniões?',
  ];

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(GjaIcons.ai, size: 44.sp, color: cs.primary),
          SizedBox(height: AppSpacing.md),
          Text(
            'Pergunte em linguagem natural',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'A resposta é sintetizada a partir das ATAs indexadas, '
            'sempre com as fontes citadas.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              for (final exemplo in _exemplos)
                // Cores explícitas do scheme para funcionar nos temas claro e escuro.
                ActionChip(
                  avatar: Icon(GjaIcons.search, size: 16, color: cs.primary),
                  label: Text(exemplo),
                  labelStyle: context.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurface),
                  backgroundColor: cs.surfaceContainerHigh,
                  side: BorderSide(color: cs.outlineVariant),
                  onPressed: () => onPick(exemplo),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Resultado
// ─────────────────────────────────────────────────────────────────────────────

class _Resultado extends StatelessWidget {
  const _Resultado({
    required this.wide,
    required this.resposta,
    required this.pergunta,
    required this.onCopiar,
  });

  final bool wide;
  final RagResposta resposta;
  final String? pergunta;
  final VoidCallback onCopiar;

  @override
  Widget build(BuildContext context) {
    final r = resposta;

    if (r.fontes.isEmpty && r.resposta.trim().isEmpty) {
      return const AppEmptyState(
        icon: GjaIcons.sysFind,
        title: 'Nenhuma ATA corresponde aos filtros',
        subtitle: 'Tente reformular a pergunta ou remover filtros.',
      );
    }

    final principal = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (r.resposta.trim().isNotEmpty)
          _RespostaCard(
            resposta: r.resposta,
            pergunta: pergunta,
            onCopiar: onCopiar,
          ),
        if (r.responsaveis.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          _Responsaveis(nomes: r.responsaveis),
        ],
        if (r.pontosAConfirmar.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          _PontosAConfirmar(pontos: r.pontosAConfirmar),
        ],
      ],
    );

    final fontes = _Fontes(fontes: r.fontes);

    if (wide && r.fontes.isNotEmpty) {
      // Resposta em foco + fontes no painel lateral.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: principal),
          SizedBox(width: AppSpacing.md),
          SizedBox(width: 380, child: fontes),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        principal,
        if (r.fontes.isNotEmpty) ...[
          SizedBox(height: AppSpacing.lg),
          fontes,
        ],
      ],
    );
  }
}

class _RespostaCard extends StatelessWidget {
  const _RespostaCard({
    required this.resposta,
    required this.pergunta,
    required this.onCopiar,
  });

  final String resposta;
  final String? pergunta;
  final VoidCallback onCopiar;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;

    return AppCard(
      color: cs.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(GjaIcons.ai,
                  size: 18.sp, color: cs.onPrimaryContainer),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  pergunta == null || pergunta!.isEmpty
                      ? 'Resposta'
                      : pergunta!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copiar resposta',
                icon: Icon(GjaIcons.copy,
                    size: 18.sp, color: cs.onPrimaryContainer),
                onPressed: onCopiar,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          MarkdownView(data: resposta),
        ],
      ),
    );
  }
}

class _Responsaveis extends StatelessWidget {
  const _Responsaveis({required this.nomes});
  final List<String> nomes;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    final cs = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Responsáveis',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final nome in nomes)
              // Cores explícitas do scheme para funcionar no tema escuro.
              Chip(
                avatar: Icon(GjaIcons.personPlaceholder,
                    size: 16, color: cs.onSurfaceVariant),
                label: Text(nome),
                labelStyle: tt.bodySmall?.copyWith(color: cs.onSurface),
                backgroundColor: cs.surfaceContainerHigh,
                side: BorderSide(color: cs.outlineVariant),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}

class _Fontes extends StatelessWidget {
  const _Fontes({required this.fontes});
  final List<Fonte> fontes;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fontes (${fontes.length})',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        SizedBox(height: AppSpacing.sm),
        for (final fonte in fontes)
          FonteCard(
            fonte: fonte,
            onTap: () =>
                context.push(AppRoutes.teamsbotAtaDetalhePath(fonte.ataId)),
          ),
      ],
    );
  }
}

class _PontosAConfirmar extends StatelessWidget {
  const _PontosAConfirmar({required this.pontos});
  final List<String> pontos;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final tt = context.textTheme;

    return AppCard(
      color: ac.warningContainer ?? ac.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(GjaIcons.warning,
                  size: 18.sp, color: ac.onWarningContainer ?? ac.onWarning),
              SizedBox(width: AppSpacing.xs),
              Text('Pontos a confirmar',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ac.onWarningContainer ?? ac.onWarning,
                  )),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          for (final p in pontos)
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxs),
              child: Text('• $p',
                  style: tt.bodyMedium?.copyWith(
                    color: ac.onWarningContainer ?? ac.onWarning,
                  )),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filtros
// ─────────────────────────────────────────────────────────────────────────────

class _FiltrosTile extends StatelessWidget {
  const _FiltrosTile({
    required this.empresa,
    required this.participante,
    required this.dataInicio,
    required this.dataFim,
    required this.onPickInicio,
    required this.onPickFim,
  });

  final TextEditingController empresa;
  final TextEditingController participante;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final ValueChanged<DateTime?> onPickInicio;
  final ValueChanged<DateTime?> onPickFim;

  int _countAtivos() {
    var count = 0;
    for (final c in [empresa, participante]) {
      if (c.text.trim().isNotEmpty) count++;
    }
    if (dataInicio != null) count++;
    if (dataFim != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: ListenableBuilder(
          listenable: Listenable.merge([empresa, participante]),
          builder: (context, _) {
            final n = _countAtivos();
            return Text(n == 0 ? 'Filtros (opcional)' : 'Filtros ($n ativos)');
          },
        ),
        leading: const Icon(GjaIcons.filter),
        childrenPadding:
            EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 640;
            final width = narrow ? constraints.maxWidth : 200.0;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                SizedBox(
                  width: width,
                  child: EmpresaField(controller: empresa, emptyLabel: 'Todas'),
                ),
                _FilterField(
                    label: 'Participante',
                    controller: participante,
                    width: width),
                _DateField(
                  label: 'Data início',
                  value: dataInicio,
                  onPick: onPickInicio,
                  width: width,
                ),
                _DateField(
                  label: 'Data fim',
                  value: dataFim,
                  onPick: onPickFim,
                  width: width,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.label,
    required this.controller,
    required this.width,
  });

  final String label;
  final TextEditingController controller;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppTextField(label: label, controller: controller),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.width,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPick;
  final double width;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _pick(context),
              borderRadius: AppBorders.input,
              child: IgnorePointer(
                child: AppTextField(
                  label: label,
                  hint: 'dd/mm/aaaa',
                  controller: TextEditingController(
                      text: value == null ? '' : AtaFormat.data(value)),
                  suffixIcon:
                      const Icon(GjaIcons.calendar, size: 18),
                ),
              ),
            ),
          ),
          if (value != null)
            IconButton(
              tooltip: 'Limpar',
              icon: const Icon(GjaIcons.decline, size: 18),
              onPressed: () => onPick(null),
            ),
        ],
      ),
    );
  }
}
