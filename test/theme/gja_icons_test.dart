import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Os ícones do portal vêm do catálogo do GJA (`GjaIcons`, Lucide), não
/// do Material: misturar os dois deixa traços e cantos diferentes lado a lado.
///
/// A exceção é o ícone de funcionalidade, cujo nome vem do backend no padrão
/// Material Symbols (`feature_icon.dart`).
void main() {
  test('nenhum Icons.* do Material fora do ícone de funcionalidade', () {
    const permitidos = {'lib/src/features/access/utils/feature_icon.dart'};
    final uso = RegExp(r'(?<![A-Za-z])Icons\.[a-z]');
    final violacoes = <String>[];

    for (final entidade in Directory('lib').listSync(recursive: true)) {
      if (entidade is! File || !entidade.path.endsWith('.dart')) continue;
      final caminho = entidade.path.replaceAll(r'\', '/');
      if (permitidos.contains(caminho)) continue;
      final linhas = entidade.readAsLinesSync();
      for (var i = 0; i < linhas.length; i++) {
        if (uso.hasMatch(linhas[i])) violacoes.add('$caminho:${i + 1}');
      }
    }

    expect(violacoes, isEmpty, reason: 'use GjaIcons no lugar de Icons');
  });
}
