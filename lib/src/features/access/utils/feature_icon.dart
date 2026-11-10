import 'package:flutter/material.dart';
import 'package:material_symbols_icons/get.dart';

/// Style used for feature icons — matches the default look on
/// fonts.google.com/icons (outlined).
const SymbolStyle featureIconStyle = SymbolStyle.outlined;

/// Resolves a Material Symbols icon name (as listed on fonts.google.com/icons)
/// to its [IconData]. Returns [Icons.apps] when missing or unknown.
IconData iconForFeature(String? name) {
  if (name == null || name.isEmpty) return Icons.apps;
  if (!SymbolsGet.map.containsKey(name)) return Icons.apps;
  return SymbolsGet.get(name, featureIconStyle);
}

/// Whether [name] is a known Material Symbols icon name.
bool isKnownFeatureIcon(String? name) =>
    name != null && name.isNotEmpty && SymbolsGet.map.containsKey(name);
