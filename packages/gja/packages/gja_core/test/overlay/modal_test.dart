import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_core/gja_core.dart';

/// Elemento focável de teste, com tamanho fixo.
Widget _focusable(FocusNode node, {String? label, VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Focus(
      focusNode: node,
      child: SizedBox(
        width: 80,
        height: 40,
        child: label == null ? null : Text(label),
      ),
    ),
  );
}

/// App com uma tela cujo [home] recebe o contexto abaixo do `Navigator`.
Future<void> _pumpApp(WidgetTester tester, WidgetBuilder home) {
  return tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      localizationsDelegates: const [GjaLocalizations.delegate],
      supportedLocales: GjaLocalizations.supportedLocales,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
      home: Builder(builder: home),
    ),
  );
}

/// Rótulos de todos os nós da árvore de semântica.
List<String> _semanticLabels(WidgetTester tester) {
  final labels = <String>[];
  bool visit(SemanticsNode node) {
    if (node.label.isNotEmpty) labels.add(node.label);
    node.visitChildren(visit);
    return true;
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return labels;
}

void main() {
  late BuildContext screen;

  Widget home(BuildContext context, {Widget? extra}) {
    screen = context;
    return Align(
      alignment: Alignment.topLeft,
      child: Column(mainAxisSize: MainAxisSize.min, children: [?extra]),
    );
  }

  Future<String?> open(WidgetTester tester, {bool dismissible = true}) {
    final result = GjaModal.show<String>(
      screen,
      dismissible: dismissible,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop('ok'),
        child: const SizedBox(width: 100, height: 100, child: Text('modal')),
      ),
    );
    return result;
  }

  group('Modal com camada de bloqueio', () {
    testWidgets('Modal com camada de bloqueio — Interação bloqueada', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      await _pumpApp(
        tester,
        (context) => home(
          context,
          extra: GestureDetector(
            onTap: () => taps++,
            child: Semantics(
              button: true,
              label: 'fundo',
              child: const SizedBox(width: 60, height: 40),
            ),
          ),
        ),
      );
      final point = tester.getCenter(find.bySemanticsLabel('fundo'));
      unawaited(open(tester));
      await tester.pumpAndSettle();
      expect(_semanticLabels(tester), isNot(contains('fundo')));

      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(taps, 0);
      semantics.dispose();
    });

    testWidgets('Modal com camada de bloqueio — Resultado ao fechar', (
      tester,
    ) async {
      await _pumpApp(tester, home);
      final first = open(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('modal'));
      await tester.pumpAndSettle();
      expect(await first, 'ok');

      final second = open(tester);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(await second, isNull);
    });
  });

  group('Foco no modal', () {
    testWidgets('Foco no modal — Tab preso no modal', (tester) async {
      final outside = [FocusNode(), FocusNode()];
      final inside = [FocusNode(), FocusNode()];
      addTearDown(() {
        for (final n in [...outside, ...inside]) {
          n.dispose();
        }
      });
      await _pumpApp(
        tester,
        (context) => home(
          context,
          extra: Column(children: [for (final n in outside) _focusable(n)]),
        ),
      );
      unawaited(
        GjaModal.show<void>(
          screen,
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [for (final n in inside) _focusable(n)],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ao abrir, o foco já está no primeiro elemento do modal.
      expect(inside[0].hasPrimaryFocus, isTrue);
      final visited = <FocusNode>[];
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        visited.add(FocusManager.instance.primaryFocus!);
      }
      expect(visited, [inside[1], inside[0], inside[1]]);
      expect(outside.any((n) => n.hasFocus), isFalse);
    });

    testWidgets('Foco no modal — Foco devolvido', (tester) async {
      final opener = FocusNode();
      addTearDown(opener.dispose);
      await _pumpApp(
        tester,
        (context) => home(context, extra: _focusable(opener)),
      );
      opener.requestFocus();
      await tester.pump();

      unawaited(open(tester));
      await tester.pumpAndSettle();
      expect(opener.hasFocus, isFalse);

      await tester.tap(find.text('modal'));
      await tester.pumpAndSettle();
      expect(opener.hasPrimaryFocus, isTrue);
    });
  });

  group('Dispensa do modal', () {
    testWidgets('Dispensa do modal — Dispensa por Esc e pela camada', (
      tester,
    ) async {
      await _pumpApp(tester, home);
      final byEsc = open(tester);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('modal'), findsNothing);
      expect(await byEsc, isNull);

      // Como no sap.m.Dialog, a camada não é interativa.
      unawaited(open(tester));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('modal'), findsOneWidget);
    });

    testWidgets('Dispensa do modal — Modal não dispensável', (tester) async {
      await _pumpApp(tester, home);
      unawaited(open(tester, dismissible: false));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('modal'), findsOneWidget);
    });

    testWidgets('Dispensa do modal — Camada sem semântica', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpApp(tester, home);
      unawaited(open(tester));
      await tester.pumpAndSettle();
      // O idioma do ambiente de teste é en-US.
      expect(_semanticLabels(tester), isNot(contains('Close')));
      // Camada não dispensável: sem toque nem ação na semântica.
      expect(
        tester
            .widgetList<ModalBarrier>(find.byType(ModalBarrier))
            .every((barrier) => !barrier.dismissible),
        isTrue,
      );
      semantics.dispose();
    });
  });
}
