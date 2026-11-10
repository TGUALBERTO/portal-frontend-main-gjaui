import 'package:flutter/widgets.dart' show IconData;

/// View-model for a single Home card.
///
/// Built from a backend [Permission] + the frontend route registry. Carries
/// everything the Home needs to render and act on a card: identifier, title,
/// icon, target route and enablement status.
class HomeFeature {
  const HomeFeature({
    required this.code,
    required this.title,
    required this.icon,
    required this.module,
    this.route,
  });

  /// Backend feature code — registry lookup key and tap-handler argument.
  final String code;

  /// Display label (feature.label).
  final String title;

  /// Resolved icon (iconForFeature(feature.iconName)).
  final IconData icon;

  /// Module display label, used as the section title when grouping cards.
  final String module;

  /// go_router route from the registry; null means "em breve" (no route yet).
  final String? route;

  /// True when the feature has a navigable route.
  bool get isEnabled => route != null;
}
