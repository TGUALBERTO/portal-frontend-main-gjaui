import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _declaration = RegExp(
  r'^(?:@\w+\s*)*(?:(?:abstract|base|final|sealed|interface|mixin)\s+)*(?:class|mixin)\s+([A-Z]\w*)',
);
final _level = RegExp(r'^///\s*Nível:\s*(primitivo|semântico|componente)\b');

/// Classes públicas de [root] sem a linha `Nível:` no dartdoc.
List<String> undocumentedLevels(Directory root) {
  final missing = <String>[];
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
  for (final file in files) {
    final lines = file.readAsLinesSync();
    for (final (index, line) in lines.indexed) {
      final match = _declaration.firstMatch(line.trim());
      if (match == null) continue;
      var docStart = index;
      while (docStart > 0 &&
          (lines[docStart - 1].trimLeft().startsWith('///') ||
              lines[docStart - 1].trimLeft().startsWith('@'))) {
        docStart--;
      }
      final documented = lines
          .sublist(docStart, index)
          .any((l) => _level.hasMatch(l.trimLeft()));
      if (!documented) missing.add('${file.path}: ${match.group(1)}');
    }
  }
  return missing;
}

void main() {
  test('Três níveis de tokens — Nível documentado', () {
    for (final path in [
      'lib/src/tokens',
      'lib/src/color',
      'lib/src/spacing',
      'lib/src/typography',
      'lib/src/radius',
      'lib/src/breakpoints',
      'lib/src/iconography',
      'lib/src/density',
      'lib/src/shadows',
      'lib/src/interaction_states',
      'lib/src/accessibility',
      'lib/src/theming',
    ]) {
      final root = Directory(path);
      expect(root.existsSync(), isTrue, reason: path);
      expect(undocumentedLevels(root), isEmpty, reason: path);
    }
  });
}
