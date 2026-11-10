import 'package:flutter/widgets.dart';
import 'package:gja_foundation/gja_foundation.dart';

import 'initial_focus.dart';

/// Abre conteúdos modais sobre a tela, com camada de bloqueio.
///
/// Equivale ao modal do `sap.ui.core.Popup` do SAPUI5: a camada (*block
/// layer*) cobre a tela, o conteúdo abaixo não recebe toques nem semântica, o
/// foco fica preso no modal e volta a quem o abriu ao fechar.
abstract final class GjaModal {
  /// Abre o conteúdo de [builder] como modal e espera o resultado.
  ///
  /// Feche com `Navigator.of(context).pop(resultado)` de dentro do conteúdo.
  /// Como o `sap.m.Dialog`, quando [dismissible] é verdadeiro, Esc fecha o
  /// modal com resultado nulo; sem ele, Esc é ignorado. A camada nunca é
  /// interativa: um toque nela não fecha o modal, e ela não tem rótulo nem
  /// ação na árvore de semântica. A camada usa [blockLayerColor] ou, sem ele,
  /// o `blockLayer` do tema ativo (`GjaThemeData.of`).
  ///
  /// O foco inicial é o do elemento com `autofocus`; sem nenhum, o primeiro
  /// elemento focável do modal recebe o foco.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool dismissible = true,
    Color? blockLayerColor,
    bool useRootNavigator = true,
  }) {
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    return navigator.push<T>(
      _GjaModalRoute<T>(
        dismissible: dismissible,
        blockLayerColor:
            blockLayerColor ?? GjaThemeData.of(context).colors.blockLayer,
        pageBuilder: (context, _, _) => SafeArea(
          child: Center(child: GjaInitialFocus(child: builder(context))),
        ),
      ),
    );
  }
}

/// Rota do modal: Esc fecha conforme [dismissible] (tratado pela própria
/// rota), e a camada de bloqueio é inerte, sem toque nem semântica.
class _GjaModalRoute<T> extends RawDialogRoute<T> {
  _GjaModalRoute({
    required bool dismissible,
    required Color blockLayerColor,
    required super.pageBuilder,
  }) : super(
         barrierDismissible: dismissible,
         barrierColor: blockLayerColor,
         transitionDuration: Duration.zero,
       );

  @override
  Widget buildModalBarrier() =>
      ModalBarrier(color: barrierColor, dismissible: false);
}
