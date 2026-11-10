import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_foundation/gja_foundation.dart';
import 'package:gja_foundation/gja_primitives.dart';

/// Mapa oficial empacotado (nome Lucide → código).
Map<String, int> _codepoints() =>
    (jsonDecode(File('fonts/lucide/codepoints.json').readAsStringSync())
            as Map<String, dynamic>)
        .cast<String, int>();

const _minimum = [
  'add', 'decline', 'search', 'accept', 'slimArrowUp', 'slimArrowDown', //
  'slimArrowLeft', 'slimArrowRight', 'navBack', 'navigationRightArrow',
  'menu2', 'overflow', 'edit', 'delete', 'information', 'warning', 'error',
  'sysEnter2', 'sysHelp', 'calendar', 'pending', 'personPlaceholder',
  'filter', 'sort', 'upload', 'download', 'refresh', 'actionSettings', 'home',
  'popupWindow', 'show', 'hide', 'copy', 'log', 'bell', 'document',
  'folderBlank',
];

const _directional = {
  'slimArrowLeft',
  'slimArrowRight',
  'navBack',
  'navigationRightArrow',
  'log',
  'popupWindow',
  'journeyArrive',
  'sysFirstPage',
  'sysLastPage',
};

/// Se o `Icon` inseriu o espelhamento horizontal (`Transform` com escala -1).
bool _isMirrored(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(
    find.descendant(of: find.byType(Icon), matching: find.byType(Transform)),
  );
  return transforms.any((t) => t.transform.storage[0] == -1);
}

void main() {
  group('Catálogo semântico de ícones', () {
    test(
      'Catálogo semântico de ícones — Códigos conferem com o mapa oficial',
      () {
        final codepoints = _codepoints();
        expect(GjaIcons.lucideNames.keys, GjaIcons.all.keys);
        for (final MapEntry(key: name, value: icon) in GjaIcons.all.entries) {
          final lucide = GjaIcons.lucideNames[name]!;
          expect(codepoints, contains(lucide), reason: name);
          expect(icon.codePoint, codepoints[lucide], reason: '$name → $lucide');
          expect(icon.fontFamily, 'Lucide', reason: name);
          expect(icon.fontPackage, 'gja_foundation', reason: name);
        }
      },
    );

    test(
      'Catálogo semântico de ícones — Catálogo completo e sem repetição',
      () {
        expect(GjaIcons.all.keys, containsAll(_minimum));
        final codes = GjaIcons.all.values.map((i) => i.codePoint).toList();
        expect(codes.toSet(), hasLength(codes.length));
      },
    );

    test('Catálogo semântico de ícones — Nomes do IconPool', () {
      // Nome do IconPool em camelCase: sem hífens, letra seguinte maiúscula.
      String camel(String pool) => pool.replaceAllMapped(
        RegExp('-([a-z0-9])'),
        (m) => m[1]!.toUpperCase(),
      );
      expect(GjaIcons.iconPoolNames.keys, GjaIcons.all.keys);
      for (final MapEntry(key: name, value: pool)
          in GjaIcons.iconPoolNames.entries) {
        expect(camel(pool), name, reason: pool);
      }
      expect(GjaIcons.iconPoolNames['slimArrowDown'], 'slim-arrow-down');
      expect(GjaIcons.iconPoolNames['sysEnter2'], 'sys-enter-2');
      expect(GjaIcons.iconPoolNames['menu2'], 'menu2');
      for (final old in [
        'close',
        'check',
        'chevronDown',
        'user',
        'moreVertical',
        'info',
        'clock',
      ]) {
        expect(GjaIcons.all.keys, isNot(contains(old)), reason: old);
      }
    });
  });

  testWidgets('Espelhamento de ícones direcionais — Ícone direcional em RTL', (
    tester,
  ) async {
    for (final MapEntry(key: name, value: icon) in GjaIcons.all.entries) {
      expect(
        icon.matchTextDirection,
        _directional.contains(name),
        reason: name,
      );
    }
    for (final (icon, mirrored) in [
      (GjaIcons.slimArrowRight, true),
      (GjaIcons.accept, false),
    ]) {
      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.rtl, child: Icon(icon)),
      );
      expect(_isMirrored(tester), mirrored, reason: '${icon.codePoint}');
    }
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Icon(GjaIcons.slimArrowRight),
      ),
    );
    expect(_isMirrored(tester), isFalse);
  });

  test('Uso de ícones fora do catálogo — Ícone extra da aplicação', () {
    final anchorCode = _codepoints()['anchor']!;
    final anchor = IconData(
      anchorCode,
      fontFamily: GjaIconPrimitives.fontFamily,
      fontPackage: GjaIconPrimitives.fontPackage,
    );
    expect(anchor.fontFamily, GjaIcons.add.fontFamily);
    expect(anchor.fontPackage, GjaIcons.add.fontPackage);
    expect(
      GjaIcons.all.values.map((i) => i.codePoint),
      isNot(contains(anchorCode)),
    );
  });

  test('Escala primitiva de tamanhos de ícone — Escala em ordem', () {
    final entries = GjaIconPrimitives.sizes.entries.toList();
    for (final (i, MapEntry(key: name, value: value)) in entries.indexed) {
      expect(double.parse(name.substring('size'.length)), value, reason: name);
      if (i > 0) expect(value, greaterThan(entries[i - 1].value), reason: name);
    }
    expect(
      GjaIconPrimitives.sizes.values,
      containsAll(<double>[12, 16, 20, 24, 32, 40, 48]),
    );
  });
}
