import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

/// Exibe texto corrido do GJA, como o `sap.m.Text` do SAPUI5.
///
/// Usa o estilo `base` e a cor `text` do tema ativo. Com [maxLines], o texto
/// termina com reticências quando não cabe; sem [wrapping], fica em uma linha
/// com reticências e [maxLines] é ignorado. O leitor de tela lê o texto
/// completo. Títulos usam `GjaTitle`, e rótulos, `GjaLabel`.
///
/// ```dart
/// GjaText('Pedido 4711 aguardando aprovação', maxLines: 2)
/// GjaText('Fornecedor central', wrapping: false)
/// ```
class GjaText extends StatelessWidget {
  /// Cria o texto [text].
  const GjaText(
    this.text, {
    this.maxLines,
    this.wrapping = true,
    this.textAlign = TextAlign.start,
    super.key,
  }) : assert(
         maxLines == null || maxLines > 0,
         '"maxLines" deve ser maior que zero',
       );

  /// Texto exibido.
  final String text;

  /// Número máximo de linhas; nulo não limita. Ignorado sem [wrapping].
  final int? maxLines;

  /// Se o texto quebra linhas; sem quebra, ocupa uma linha com reticências.
  final bool wrapping;

  /// Alinhamento horizontal.
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = GjaThemeData.of(context);
    final lines = wrapping ? maxLines : 1;
    return Text(
      text,
      style: theme.typography.base.copyWith(color: theme.colors.text),
      maxLines: lines,
      overflow: lines == null ? TextOverflow.clip : TextOverflow.ellipsis,
      textAlign: textAlign,
      softWrap: wrapping,
    );
  }
}
