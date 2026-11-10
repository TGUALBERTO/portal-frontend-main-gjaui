import 'package:gja_ui/gja_ui.dart' show GjaBusyIndicator;

import '../../imports/imports.dart';

/// Centered loading indicator.
///
/// Desenhado pelo [GjaBusyIndicator] (`sap.m.BusyIndicator`): três pontos
/// pulsantes na cor da marca e, opcionalmente, o [message] abaixo.
///
/// Usage:
/// ```dart
/// // Simple inline loader
/// const AppLoading()
///
/// // Full-screen loader with message
/// AppLoading(message: 'Fetching data...')
/// ```
class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.message,
    this.size = 28,
    this.strokeWidth = 3,
  });

  final String? message;

  /// Sem efeito desde a adoção do GJA; mantido por compatibilidade.
  final double size;

  /// Sem efeito desde a adoção do GJA; mantido por compatibilidade.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Center(child: GjaBusyIndicator(text: message));
  }
}
