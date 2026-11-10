// Gera as capturas da galeria usadas no README, com as fontes reais.
//
// Não faz parte da suíte de testes (fica fora de `test/`). Para atualizar as
// imagens em `docs/screenshots/`:
//
//   cd apps/gja_gallery
//   flutter test tool/screenshots/screenshots_test.dart --update-goldens
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gja_gallery/main.dart';
import 'package:gja_gallery/pages/gja_date_picker_page.dart';
import 'package:gja_gallery/pages/gja_form_page.dart';
import 'package:gja_gallery/pages/gja_shell_bar_page.dart';
import 'package:gja_gallery/pages/gja_side_navigation_page.dart';
import 'package:gja_gallery/pages/gja_table_page.dart';
import 'package:gja_ui/gja_ui.dart';

import '../../test/support/inter_font.dart';
import '../../test/support/lucide_font.dart';
import '../../test/support/navigation.dart';

/// Abre a galeria em 1280 × 800, no tema [brightness], em pt-BR, e, com
/// [page], vai até essa página.
Future<void> _open(
  WidgetTester tester, {
  String? page,
  Brightness brightness = Brightness.light,
}) async {
  await loadInterFont();
  await loadLucideFont();
  // Capturas como a aplicação real: sem a faixa de depuração e com as
  // sombras, que o ambiente de teste desliga.
  WidgetsApp.debugAllowBannerOverride = false;
  debugDisableShadows = false;
  addTearDown(() => WidgetsApp.debugAllowBannerOverride = true);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 800);
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  tester.platformDispatcher.localesTestValue = const [Locale('pt', 'BR')];
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(const GjaGalleryApp());
  await tester.pumpAndSettle();
  if (page != null) await openGalleryPage(tester, page);
}

/// Salva a tela em `docs/screenshots/[name].png` e volta as sombras ao padrão
/// dos testes, que o ambiente confere antes do fim de cada teste.
Future<void> _capture(String name) async {
  await expectLater(
    find.byType(GjaGalleryApp),
    matchesGoldenFile('../../../../docs/screenshots/$name.png'),
  );
  debugDisableShadows = true;
}

void main() {
  testWidgets('índice da galeria', (tester) async {
    await _open(tester);
    await _capture('01-galeria');
  });

  testWidgets('tabela', (tester) async {
    await _open(tester, page: GjaTablePage.title);
    await _capture('02-tabela');
  });

  testWidgets('formulário no tema escuro', (tester) async {
    await _open(tester, page: GjaFormPage.title, brightness: Brightness.dark);
    await _capture('03-formulario-escuro');
  });

  testWidgets('seletor de data com o calendário aberto', (tester) async {
    await _open(tester, page: GjaDatePickerPage.title);
    await tester.tap(find.byIcon(GjaIcons.calendar).first);
    await tester.pumpAndSettle();
    await _capture('04-seletor-de-data');
  });

  testWidgets('navegação lateral no tema escuro', (tester) async {
    await _open(
      tester,
      page: GjaSideNavigationPage.title,
      brightness: Brightness.dark,
    );
    await _capture('05-navegacao-lateral-escuro');
  });

  testWidgets('barra de shell', (tester) async {
    await _open(tester, page: GjaShellBarPage.title);
    await _capture('06-barra-de-shell');
  });
}
