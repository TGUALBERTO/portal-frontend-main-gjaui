import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gjamobile/src/features/auth/presentation/widgets/login_view.dart';
import 'package:gjamobile/src/features/auth/presentation/widgets/truck_painter.dart';
import 'package:gjamobile/src/shared/wrappers/screen_util_wrapper.dart';
import 'package:gjamobile/src/theme/theme_constants.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Ver `contagem_cega_responsividade_test.dart`: reaproveitando o tester entre
/// os temas, só depois da animação do `AnimatedTheme` o tema pedido vale.
const _animacaoDeTema = Duration(milliseconds: 400);

/// Insets de um Android com barra de status e navegação por 3 botões.
const _androidRetratoTop = 24.0;
const _androidRetratoBottom = 48.0;
const _androidRetrato =
    FakeViewPadding(top: _androidRetratoTop, bottom: _androidRetratoBottom);
const _androidDeitado = FakeViewPadding(top: 24, right: 48);

void main() {
  const primaria = '#de3438';

  final temas = <String, ThemeData>{
    'claro': buildLightTheme(primaryColorHex: primaria),
    'escuro': buildDarkTheme(primaryColorHex: primaria),
  };

  const viewports = <String, (Size, FakeViewPadding)>{
    'Android pequeno (320x568)': (Size(320, 568), _androidRetrato),
    'Android padrão (360x780)': (Size(360, 780), _androidRetrato),
    'Android deitado (780x360)': (Size(780, 360), _androidDeitado),
    'coletor 540 dp (540x1080)': (Size(540, 1080), _androidRetrato),
    'tablet (800x1280)': (Size(800, 1280), _androidRetrato),
    'web notebook (1366x768)': (Size(1366, 768), FakeViewPadding.zero),
    'web desktop (1920x1080)': (Size(1920, 1080), FakeViewPadding.zero),
    'web ultrawide (2560x1440)': (Size(2560, 1440), FakeViewPadding.zero),
  };

  setUpAll(() {
    // A versão do rodapé sai do PackageInfo, nunca de um texto fixo.
    PackageInfo.setMockInitialValues(
      appName: 'gjamobile',
      packageName: 'com.gja.gjamobile',
      version: '2026.10.05.18.42',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Future<void> pump(
    WidgetTester tester, {
    required ThemeData theme,
    Size size = const Size(360, 780),
    FakeViewPadding padding = _androidRetrato,
    double textScale = 1.0,
    ReadonlySignal<bool>? isLoading,
    Future<void> Function()? onSignIn,
    VoidCallback? onLogoTap,
  }) async {
    tester.view
      ..devicePixelRatio = 1.0
      ..physicalSize = size
      ..padding = padding;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilWrapper(
        child: MaterialApp(
          theme: theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: LoginView(
            isLoading: isLoading ?? signal(false),
            onSignIn: onSignIn ?? () async {},
            onLogoTap: onLogoTap,
          ),
        ),
      ),
    );
    await tester.pump(_animacaoDeTema);
  }

  final painel = find.byWidgetPredicate(
    (w) => w.runtimeType.toString() == '_LoginPanel',
  );
  final botao = find.byType(OutlinedButton);
  final rodape = find.textContaining('Grupo José Alves');

  Color corDoPainel(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: painel, matching: find.byType(DecoratedBox)).first,
    );
    return (box.decoration as BoxDecoration).color!;
  }

  List<Color> coresDoFundo(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            (w.decoration as BoxDecoration?)?.gradient != null,
      ),
    );
    return (box.decoration as BoxDecoration).gradient!.colors;
  }

  /// Cor com que o texto é pintado de fato (já com o DefaultTextStyle do
  /// botão, no caso do rótulo).
  Color corDoTexto(WidgetTester tester, Finder texto) =>
      tester.renderObject<RenderParagraph>(texto).text.style!.color!;

  // ── Layout: viewport × tema ───────────────────────────────────────────────

  // Primeiro teste do arquivo de propósito: o AppVersionService guarda o
  // Future da versão, e um Future criado na zona fake-async de um teste já
  // encerrado nunca entrega o valor ao FutureBuilder do teste seguinte.
  testWidgets('versão no rodapé vem do app, prefixada pela empresa',
      (tester) async {
    await pump(tester, theme: temas['claro']!);
    await tester.pump();
    expect(find.text('Grupo José Alves · v2026.10.05.18.42'), findsOneWidget);
  });

  testWidgets('sem overflow em 8 viewports Android/web × 2 temas',
      (tester) async {
    for (final tema in temas.entries) {
      for (final viewport in viewports.entries) {
        final (size, padding) = viewport.value;
        await pump(tester, theme: tema.value, size: size, padding: padding);
        expect(
          tester.takeException(),
          isNull,
          reason: 'estourou no tema ${tema.key}, viewport ${viewport.key}',
        );
      }
    }
  });

  for (final escala in [1.3, 2.0]) {
    testWidgets('texto em ${escala}x cabe no Android (claro e escuro)',
        (tester) async {
      for (final tema in temas.values) {
        for (final size in const [Size(320, 568), Size(360, 780)]) {
          await pump(tester, theme: tema, size: size, textScale: escala);
          expect(tester.takeException(), isNull, reason: '$size');
        }
      }
    });
  }

  testWidgets('na web o painel para na largura de formulário, centralizado',
      (tester) async {
    for (final width in const [1366.0, 1920.0, 2560.0]) {
      await pump(
        tester,
        theme: temas['claro']!,
        size: Size(width, 900),
        padding: FakeViewPadding.zero,
      );
      final rect = tester.getRect(painel);
      expect(rect.width, AppDesignTokens.fallback.maxFormWidth);
      expect(rect.center.dx, closeTo(width / 2, 0.5));
    }
  });

  testWidgets('no Android o painel ocupa a tela menos a margem da página',
      (tester) async {
    await pump(tester, theme: temas['claro']!, size: const Size(360, 780));
    final rect = tester.getRect(painel);
    final margem = AppBreakpoints.pagePaddingFor(AppWindowSize.compact);
    expect(rect.left, margem);
    expect(rect.width, 360 - 2 * margem);
  });

  testWidgets('respeita a barra de status: nada é desenhado embaixo dela',
      (tester) async {
    await pump(tester, theme: temas['claro']!, size: const Size(320, 568));
    expect(tester.getRect(painel).top, greaterThanOrEqualTo(24));
  });

  // ── Rolagem e faixa do caminhão ───────────────────────────────────────────

  testWidgets(
      'sem altura, tudo rola junto e o caminhão nunca cobre o botão nem o '
      'rodapé', (tester) async {
    var cliques = 0;
    final faixa = find
        .ancestor(
          of: find.byType(DrivingTruck),
          matching: find.byType(IgnorePointer),
        )
        .first;

    for (final (size, padding, escala) in const [
      (Size(780, 360), _androidDeitado, 1.0),
      (Size(320, 568), _androidRetrato, 1.3),
      (Size(360, 780), _androidRetrato, 2.0),
    ]) {
      await pump(
        tester,
        theme: temas['claro']!,
        size: size,
        padding: padding,
        textScale: escala,
        onSignIn: () async => cliques++,
      );

      void semSobreposicao(String momento) {
        final caminhao = tester.getRect(faixa);
        for (final alvo in [botao, rodape]) {
          expect(
            caminhao.overlaps(tester.getRect(alvo)),
            isFalse,
            reason: '$alvo coberto pelo caminhão $momento ($size, ${escala}x)',
          );
        }
      }

      semSobreposicao('no topo');
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -2000),
      );
      await tester.pump();
      semSobreposicao('no fim da rolagem');
      expect(
        tester.getRect(rodape).bottom,
        lessThanOrEqualTo(size.height - padding.bottom),
        reason: 'rodapé alcançável rolando ($size)',
      );
    }

    await tester.ensureVisible(botao);
    await tester.pump();
    await tester.tap(botao);
    expect(cliques, 1);
  });

  testWidgets(
      'sobrando altura, o caminhão fica no pé da tela, acima da barra de '
      'navegação do Android', (tester) async {
    // 540x1080 e não 360x780: com a fonte Ahem dos testes (glifos de 1 em) o
    // painel fica bem mais alto que com a Roboto e já não caberia.
    await pump(tester, theme: temas['claro']!, size: const Size(540, 1080));
    final faixa = tester.getRect(
      find
          .ancestor(
            of: find.byType(DrivingTruck),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(faixa.bottom, 1080 - _androidRetrato.bottom);
    expect(tester.getRect(rodape).bottom, lessThanOrEqualTo(faixa.top));
  });

  /// Centro vertical do bloco painel + rodapé (o padding em volta é simétrico).
  double centroDoConteudo(WidgetTester tester) =>
      (tester.getRect(painel).top + tester.getRect(rodape).bottom) / 2;

  testWidgets(
      'no celular o conteúdo fica centralizado na tela inteira, não só '
      'acima do caminhão', (tester) async {
    // 540 dp ainda é celular (compact); ver acima o porquê de não ser 360x780.
    await pump(tester, theme: temas['claro']!, size: const Size(540, 1080));
    // Centro da área entre a barra de status e a de navegação.
    expect(
      centroDoConteudo(tester),
      closeTo((_androidRetratoTop + 1080 - _androidRetratoBottom) / 2, 0.5),
    );
  });

  testWidgets('na web o conteúdo segue centralizado acima do caminhão',
      (tester) async {
    await pump(
      tester,
      theme: temas['claro']!,
      size: const Size(1440, 900),
      padding: FakeViewPadding.zero,
    );
    expect(
      centroDoConteudo(tester),
      closeTo((900 - DrivingTruck.height) / 2, 0.5),
    );
  });

  // ── Tema: contraste e logo ────────────────────────────────────────────────

  for (final tema in temas.entries) {
    testWidgets('contraste AA de todos os textos no tema ${tema.key}',
        (tester) async {
      await pump(tester, theme: tema.value);
      await tester.pump(); // versão do PackageInfo
      final fundoDoPainel = corDoPainel(tester);

      for (final texto in [
        'ACESSO CORPORATIVO',
        'Boas-vindas',
        'Entre com sua conta corporativa Microsoft para acessar o aplicativo.',
        'Entrar com Microsoft',
        'Use seu e-mail corporativo.',
      ]) {
        final razao = _contraste(corDoTexto(tester, find.text(texto)),
            fundoDoPainel);
        expect(razao, greaterThanOrEqualTo(4.5), reason: '"$texto": $razao');
      }

      // O rodapé fica sobre o gradiente: vale contra todas as paradas.
      final corRodape = corDoTexto(tester, rodape);
      for (final parada in coresDoFundo(tester)) {
        expect(_contraste(corRodape, parada), greaterThanOrEqualTo(4.5));
      }

      // O painel precisa se destacar do fundo, e a borda do botão do painel
      // (WCAG 1.4.11: componente de interface, 3:1), inclusive com foco.
      final borda = tester.widget<OutlinedButton>(botao).style!.side!;
      expect(
        _contraste(borda.resolve({})!.color, fundoDoPainel),
        greaterThanOrEqualTo(3),
      );
      expect(
        _contraste(
            borda.resolve({WidgetState.focused})!.color, fundoDoPainel),
        greaterThanOrEqualTo(3),
      );
    });
  }

  testWidgets('a logo só ganha a placa clara no tema escuro', (tester) async {
    final placa = find.ancestor(
      of: find.byType(Image),
      matching: find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == Colors.white &&
            (w.decoration as BoxDecoration).border == null,
      ),
    );

    await pump(tester, theme: temas['claro']!);
    expect(placa, findsNothing);

    await pump(tester, theme: temas['escuro']!);
    expect(placa, findsOneWidget);
  });

  testWidgets('ícones da barra de status acompanham o tema', (tester) async {
    SystemUiOverlayStyle estilo() => tester
        .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>))
        .value;

    await pump(tester, theme: temas['claro']!);
    expect(estilo().statusBarIconBrightness, Brightness.dark);

    await pump(tester, theme: temas['escuro']!);
    expect(estilo().statusBarIconBrightness, Brightness.light);
  });

  // ── Comportamento ─────────────────────────────────────────────────────────

  testWidgets('carregando: botão desabilitado com spinner; ao terminar, volta',
      (tester) async {
    final carregando = signal(true);
    var cliques = 0;
    await pump(
      tester,
      theme: temas['claro']!,
      isLoading: carregando,
      onSignIn: () async => cliques++,
    );

    expect(tester.widget<OutlinedButton>(botao).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Entrar com Microsoft'), findsOneWidget);
    await tester.tap(botao);
    expect(cliques, 0);

    // Spinner e caminhão giram para sempre, então nada de pumpAndSettle: dá
    // tempo de sobra para a troca do AnimatedSwitcher terminar e o spinner
    // sair da árvore.
    carregando.value = false;
    await tester.pump();
    await tester.pump(AppDurations.normal);
    await tester.pump(AppDurations.normal);

    expect(tester.widget<OutlinedButton>(botao).onPressed, isNotNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(botao);
    expect(cliques, 1);
  });

  testWidgets('web: Tab chega ao botão com anel de foco visível e Enter entra', (tester) async {
    var cliques = 0;
    await pump(
      tester,
      theme: temas['claro']!,
      size: const Size(1366, 768),
      padding: FakeViewPadding.zero,
      onSignIn: () async => cliques++,
    );

    BorderSide bordaDesenhada() {
      final material = tester.widget<Material>(
        find.descendant(of: botao, matching: find.byType(Material)).first,
      );
      return (material.shape! as OutlinedBorder).side;
    }

    final semFoco = bordaDesenhada();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(AppDurations.normal);
    final foco = FocusManager.instance.primaryFocus!.context!;
    expect(
      find.ancestor(of: find.byElementPredicate((e) => e == foco),
          matching: botao),
      findsOneWidget,
    );
    // O anel de foco aparece de fato (mais grosso e na cor de destaque).
    final comFoco = bordaDesenhada();
    expect(comFoco.color, temas['claro']!.colorScheme.primary);
    expect(comFoco.width, greaterThan(semFoco.width));

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(cliques, 1);
  });

  testWidgets('área de toque do botão tem ao menos 48 dp', (tester) async {
    await pump(tester, theme: temas['claro']!, size: const Size(320, 568));
    expect(tester.getSize(botao).height, greaterThanOrEqualTo(48));
  });

  testWidgets(
      'toque na logo chega à tela (seletor de ambiente), mas a logo não é '
      'anunciada como botão', (tester) async {
    final semantics = tester.ensureSemantics();
    var toques = 0;
    await pump(tester, theme: temas['claro']!, onLogoTap: () => toques++);

    await tester.tap(find.byType(Image));
    expect(toques, 1);

    expect(
      tester.getSemantics(find.bySemanticsLabel('Grupo José Alves').first),
      isNot(containsSemantics(hasTapAction: true)),
    );
    expect(
      tester.getSemantics(find.text('Boas-vindas')),
      containsSemantics(isHeader: true),
    );
    semantics.dispose();
  });
}

/// Razão de contraste WCAG entre duas cores opacas.
double _contraste(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final claro = math.max(l1, l2);
  final escuro = math.min(l1, l2);
  return (claro + 0.05) / (escuro + 0.05);
}
