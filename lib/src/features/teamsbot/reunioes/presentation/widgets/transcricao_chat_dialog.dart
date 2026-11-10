import 'package:gjamobile/src/di/app_injector.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/data/models/models.dart';
import 'package:gjamobile/src/features/teamsbot/reunioes/data/repositories/reunioes_repository.dart';
import 'package:gjamobile/src/imports/imports.dart';
import 'package:gja_ui/gja_ui.dart' show GjaIcons;

/// Abre o diálogo com a transcrição da reunião exibida como um chat.
Future<void> showTranscricaoChatDialog({
  required int meetingId,
  String? titulo,
}) {
  return showAppDialog<void>(
    child: _TranscricaoChatDialog(meetingId: meetingId, titulo: titulo),
  );
}

class _TranscricaoChatDialog extends StatefulWidget {
  const _TranscricaoChatDialog({required this.meetingId, this.titulo});

  final int meetingId;
  final String? titulo;

  @override
  State<_TranscricaoChatDialog> createState() => _TranscricaoChatDialogState();
}

class _TranscricaoChatDialogState extends State<_TranscricaoChatDialog> {
  late Future<AppResult<TranscricaoConteudo>> _future;

  /// `false` = bruta (chat); `true` = sanitizada (texto).
  bool _sanitizada = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = AppInjector.get<ReunioesRepository>()
        .transcricaoConteudo(widget.meetingId);
  }

  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: cs.surface,
      insetPadding: EdgeInsets.all(AppSpacing.lg),
      shape: const RoundedRectangleBorder(borderRadius: AppBorders.lg),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: size.height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
              child: Row(
                children: [
                  Icon(GjaIcons.discussion, color: cs.primary, size: 22.sp),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Transcrição',
                            style: tt.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        if (widget.titulo != null && widget.titulo!.isNotEmpty)
                          Text(
                            widget.titulo!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(GjaIcons.decline),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Corpo
            Flexible(
              child: FutureBuilder<AppResult<TranscricaoConteudo>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: AppLoading(message: 'Carregando transcrição…'),
                    );
                  }
                  final result = snapshot.data;
                  if (result == null) {
                    return _erro(onRetry: _retry);
                  }
                  return result.fold(
                    (conteudo) => _conteudo(conteudo),
                    (failure) =>
                        _erro(message: failure.message, onRetry: _retry),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _erro({String? message, required VoidCallback onRetry}) => Padding(
        padding: const EdgeInsets.all(24),
        child: AppErrorWidget(
          title: 'Não foi possível carregar a transcrição',
          message: message,
          onRetry: onRetry,
        ),
      );

  Widget _conteudo(TranscricaoConteudo conteudo) {
    final temToggle = conteudo.sanitizadaDisponivel;
    final sanitizada = _sanitizada && temToggle;
    return Column(
      children: [
        if (temToggle)
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Chat'),
                    icon: Icon(GjaIcons.discussion, size: 18),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Sanitizada'),
                    icon: Icon(GjaIcons.shield, size: 18),
                  ),
                ],
                selected: {sanitizada},
                onSelectionChanged: (s) =>
                    setState(() => _sanitizada = s.first),
              ),
            ),
          ),
        Expanded(
          child: sanitizada
              ? _SanitizadaView(texto: conteudo.textoSanitizado ?? '')
              : _Conteudo(conteudo: conteudo),
        ),
      ],
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.conteudo});

  final TranscricaoConteudo conteudo;

  @override
  Widget build(BuildContext context) {
    final falas = conteudo.falas;
    if (falas.isEmpty) {
      final texto = conteudo.texto;
      if (texto != null && texto.trim().isNotEmpty) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: SelectableText(texto, style: context.textTheme.bodyMedium),
        );
      }
      return const AppEmptyState(
        icon: GjaIcons.strikethrough,
        title: 'Transcrição indisponível',
        subtitle: 'Esta reunião ainda não tem conteúdo de transcrição.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.lg),
      itemCount: falas.length,
      separatorBuilder: (_, i) {
        final mesmoFalante = falas[i].falante == falas[i + 1].falante;
        return SizedBox(height: mesmoFalante ? AppSpacing.xxs : AppSpacing.md);
      },
      itemBuilder: (context, i) {
        final fala = falas[i];
        final inicioGrupo = i == 0 || falas[i - 1].falante != fala.falante;
        return _Bubble(fala: fala, mostrarCabecalho: inicioGrupo);
      },
    );
  }
}

/// Transcrição sanitizada — texto plano (sem falantes), rolável e selecionável.
class _SanitizadaView extends StatelessWidget {
  const _SanitizadaView({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    if (texto.trim().isEmpty) {
      return const AppEmptyState(
        icon: GjaIcons.shield,
        title: 'Sem texto sanitizado',
        subtitle: 'A versão sanitizada ainda não foi gerada para esta reunião.',
      );
    }
    final cs = context.colors;
    final tt = context.textTheme;
    return ListView(
      padding: EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Icon(GjaIcons.shield,
                size: 16.sp, color: cs.onSurfaceVariant),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Versão sanitizada (dados sensíveis removidos), mantida para auditoria.',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        SelectableText(texto, style: tt.bodyMedium?.copyWith(height: 1.5)),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.fala, required this.mostrarCabecalho});

  final TranscricaoFala fala;
  final bool mostrarCabecalho;

  static const _palette = <Color>[
    Color(0xFF4F9CF9),
    Color(0xFF34C759),
    Color(0xFFFF9F0A),
    Color(0xFFAF7BFF),
    Color(0xFFFF6B81),
    Color(0xFF2BC0C8),
  ];

  Color get _cor {
    final chave = (fala.falante ?? '·');
    return _palette[chave.hashCode.abs() % _palette.length];
  }

  String get _falante => (fala.falante == null || fala.falante!.isEmpty)
      ? 'Participante'
      : fala.falante!;

  String get _iniciais {
    final partes = _falante.trim().split(RegExp(r'\s+'));
    final buffer = StringBuffer();
    for (final p in partes.take(2)) {
      if (p.isNotEmpty) buffer.write(p[0].toUpperCase());
    }
    return buffer.isEmpty ? '?' : buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;
    final cor = _cor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36.w,
          child: mostrarCabecalho
              ? CircleAvatar(
                  radius: 16.r,
                  backgroundColor: cor.withValues(alpha: 0.20),
                  child: Text(_iniciais,
                      style: tt.labelSmall
                          ?.copyWith(color: cor, fontWeight: FontWeight.w700)),
                )
              : null,
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mostrarCabecalho) ...[
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _falante,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelLarge
                            ?.copyWith(color: cor, fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(_fmtTime(fala.inicioMs),
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
                SizedBox(height: AppSpacing.xxs),
              ],
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: AppBorders.md,
                ),
                child: SelectableText(fala.texto, style: tt.bodyMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Formata o offset (ms) como `mm:ss`.
  static String _fmtTime(int ms) {
    final total = ms ~/ 1000;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
