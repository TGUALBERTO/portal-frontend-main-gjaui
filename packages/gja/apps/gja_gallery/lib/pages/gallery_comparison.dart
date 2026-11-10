import 'package:flutter/widgets.dart';

/// Marca um painel que compara modos ou densidades de propósito.
///
/// O conteúdo dele usa tokens fixos (ex.: os painéis "Claro" e "Escuro" da
/// página "Cores"); o restante da página segue o tema ativo. O teste de tema
/// escuro da galeria ignora o que está dentro deste painel.
class GalleryComparison extends StatelessWidget {
  /// Marca [child] como painel de comparação.
  const GalleryComparison({required this.child, super.key});

  /// Conteúdo do painel.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
