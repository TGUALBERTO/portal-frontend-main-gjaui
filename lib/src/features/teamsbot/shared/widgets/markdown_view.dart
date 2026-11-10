import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:gjamobile/src/imports/imports.dart';

/// Renderiza Markdown com suporte a GitHub Flavored Markdown (tabelas, etc.).
///
/// Isola a dependência `flutter_markdown` — caso seja necessário trocar de
/// pacote no futuro, apenas este arquivo muda.
class MarkdownView extends StatelessWidget {
  const MarkdownView({
    super.key,
    required this.data,
    this.selectable = true,
    this.onTapLink,
  });

  final String data;
  final bool selectable;
  final MarkdownTapLinkCallback? onTapLink;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final base = MarkdownStyleSheet.fromTheme(context.theme);

    return MarkdownBody(
      data: data,
      selectable: selectable,
      onTapLink: onTapLink,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      styleSheet: base.copyWith(
        a: base.a?.copyWith(color: cs.primary),
        tableBorder: TableBorder.all(color: cs.outlineVariant),
        tableHead: base.tableHead?.copyWith(fontWeight: FontWeight.w700),
        tableCellsPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        blockquoteDecoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: AppBorders.sm,
        ),
        codeblockDecoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: AppBorders.sm,
        ),
      ),
    );
  }
}
