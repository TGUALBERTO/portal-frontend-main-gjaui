import 'package:gjamobile/src/imports/imports.dart';

/// Linha de contexto acima do título — o *kicker* do design.
///
/// Usada no corpo das telas que não têm o `ContagemAppBar` para carregá-la.
class ContagemKicker extends StatelessWidget {
  const ContagemKicker(this.texto, {super.key, this.align = TextAlign.start});

  final String texto;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      textAlign: align,
      style: context.textTheme.labelMedium?.copyWith(
        color: context.colors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Rótulo dos códigos técnicos (chave de acesso, material SAP, código do XML).
///
/// Fica em `onSurfaceVariant` para recuar em relação à descrição do material —
/// é dado de conferência, consultado quando bate dúvida, não o que se lê
/// primeiro.
class ContagemCodigo extends StatelessWidget {
  const ContagemCodigo(this.texto, {super.key, this.color});

  final String texto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: context.textTheme.bodySmall?.copyWith(
        color: color ?? context.colors.onSurfaceVariant,
      ),
    );
  }
}
