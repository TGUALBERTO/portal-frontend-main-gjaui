import 'package:flutter/material.dart';

/// Reusable border radii and border shapes used across the app.
///
/// Usage:
/// ```dart
/// Container(decoration: BoxDecoration(borderRadius: AppBorders.md))
/// ```
abstract final class AppBorders {
  AppBorders._();

  // ── Border Radii ──────────────────────────────────────────────────────────

  /// 4 pt — subtle rounding, used for small chips, badges.
  static const BorderRadius xs = BorderRadius.all(Radius.circular(4));

  /// 8 pt — standard rounding for buttons, text fields.
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));

  /// 12 pt — medium rounding for cards, list tiles.
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));

  /// 16 pt — large rounding for modals, bottom sheets.
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));

  /// 24 pt — extra large rounding for dialogs, feature cards.
  static const BorderRadius xl = BorderRadius.all(Radius.circular(24));

  /// 16 pt — topo do bottom sheet (raio `tile` do GJA).
  static const BorderRadius bottomSheet = BorderRadius.vertical(
    top: Radius.circular(16),
  );

  /// Fully circular (pill/stadium shape).
  static const BorderRadius full = BorderRadius.all(Radius.circular(999));

  // ── Semantic aliases ──────────────────────────────────────────────────────
  // Alinhados aos raios semânticos do GJA (`GjaRadiusTokens.fallback`):
  // button 8, field 4, element 12, tile 16.

  /// Default button border radius (GJA `button`).
  static const BorderRadius button = sm;

  /// Default card border radius (GJA `tile`).
  static const BorderRadius card = lg;

  /// Default input field border radius (GJA `field`).
  static const BorderRadius input = xs;

  /// Default dialog border radius (GJA `element`).
  static const BorderRadius dialog = md;

  // ── RoundedRectangleBorder shapes (for ShapeBorder APIs) ─────────────────

  /// Small rounded rectangle shape (8 pt).
  static const RoundedRectangleBorder shapeSm = RoundedRectangleBorder(
    borderRadius: sm,
  );

  /// Medium rounded rectangle shape (12 pt).
  static const RoundedRectangleBorder shapeMd = RoundedRectangleBorder(
    borderRadius: md,
  );

  /// Large rounded rectangle shape (16 pt).
  static const RoundedRectangleBorder shapeLg = RoundedRectangleBorder(
    borderRadius: lg,
  );

  /// Fully circular/stadium shape.
  static const StadiumBorder stadium = StadiumBorder();
}
