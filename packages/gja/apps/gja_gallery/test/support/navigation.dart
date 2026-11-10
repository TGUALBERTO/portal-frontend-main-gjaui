import 'package:flutter_test/flutter_test.dart';

/// Abre pelo índice da galeria a página [title]: rola até o item, garante que
/// ele esteja inteiro na tela e o toca.
///
/// O `scrollUntilVisible` para quando o item aparece só em parte, e o toque
/// pode cair fora dele; o `ensureVisible` o traz inteiro. Sem [settle], quem
/// chama avança a transição, como numa página com animação contínua.
Future<void> openGalleryPage(
  WidgetTester tester,
  String title, {
  bool settle = true,
}) async {
  final item = find.text(title);
  await tester.scrollUntilVisible(item, 200);
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  if (settle) await tester.pumpAndSettle();
}
