import 'package:gjamobile/src/imports/imports.dart';

/// Barra de ação fixa no rodapé das telas da contagem cega.
///
/// A ação principal fica sempre no mesmo lugar e ao alcance do polegar — no
/// coletor a lista de itens pode ser longa, e rolar até o fim para achar o
/// botão custa tempo em pé no doca.
class ContagemFooter extends StatelessWidget {
  const ContagemFooter({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.ms,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
