import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/teamsbot/atas/data/repositories/atas_repository.dart';
import 'package:gjamobile/src/features/teamsbot/shared/widgets/markdown_view.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Tela 3 — Editor de Markdown (`/teamsbot/atas/:id/editar`).
///
/// Editor à esquerda + preview ao vivo à direita (telas largas); abas
/// "Editar"/"Pré-visualizar" em telas estreitas.
class AtaEditorScreen extends StatefulWidget {
  const AtaEditorScreen({super.key, required this.id});

  final int id;

  @override
  State<AtaEditorScreen> createState() => _AtaEditorScreenState();
}

class _AtaEditorScreenState extends State<AtaEditorScreen> {
  final _controller = TextEditingController();
  final AtasRepository _repository = AppInjector.get<AtasRepository>();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.detalhe(widget.id);
    if (!mounted) return;
    result.onSuccess((detalhe) {
      setState(() {
        _controller.text = detalhe.markdown;
        _loading = false;
      });
    }).onFailure((failure) {
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    });
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    final result = await _repository.editar(widget.id, _controller.text);
    if (!mounted) return;
    setState(() => _saving = false);
    result.onSuccess((_) {
      showGlobalToast(
        message: 'ATA salva — nova versão gerada e reindexação iniciada.',
        status: 'success',
      );
      if (mounted) context.pop();
    }).onFailure((failure) {
      showGlobalToast(message: failure.message, status: 'error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Editar ATA #${widget.id}'),
      body: _buildBody(context),
      bottomNavigationBar: _loading || _error != null
          ? null
          : _SaveBar(
              saving: _saving,
              onSave: _salvar,
            ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const AppLoading(message: 'Carregando ATA…');
    if (_error != null) {
      return AppErrorWidget(
        title: 'Não foi possível carregar a ATA',
        message: _error,
        onRetry: _fetch,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 840) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _Editor(controller: _controller)),
              const VerticalDivider(width: 1),
              Expanded(child: _Preview(controller: _controller)),
            ],
          );
        }
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Editar'),
                  Tab(text: 'Pré-visualizar'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _Editor(controller: _controller),
                    _Preview(controller: _controller),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: controller,
        expands: true,
        maxLines: null,
        minLines: null,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        style: context.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
        decoration: const InputDecoration(
          alignLabelWithHint: true,
          hintText: 'Conteúdo Markdown da ATA…',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.md),
          child: MarkdownView(data: value.text, selectable: false),
        );
      },
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.saving, required this.onSave});
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Salvar cria uma nova versão da ATA e dispara a reindexação.',
                style: context.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            AppButton(
              label: 'Salvar',
              isLoading: saving,
              prefixIcon: const Icon(GjaIcons.save, size: 18),
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}
