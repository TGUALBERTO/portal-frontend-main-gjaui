import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:gja_checks/gja_checks.dart';
import 'package:test/test.dart';

/// Cria um repositório-fixture com [files] (caminho relativo → conteúdo).
///
/// Com [resolvable], a fixture fica dentro do workspace
/// (`tool/gja_checks/.test_tmp`), para que o analisador resolva
/// `package:flutter`. Caso contrário, usa o diretório temporário do sistema.
Repo fixtureRepo(Map<String, String> files, {bool resolvable = false}) {
  final Directory dir;
  if (resolvable) {
    final base = Directory(p.join(Directory.current.path, '.test_tmp'))..createSync(recursive: true);
    dir = base.createTempSync('fixture_');
  } else {
    dir = Directory.systemTemp.createTempSync('gja_checks_');
  }
  addTearDown(() => dir.deleteSync(recursive: true));
  Directory(p.join(dir.path, 'openspec', 'specs')).createSync(recursive: true);
  for (final MapEntry(key: path, value: content) in files.entries) {
    File(p.joinAll([dir.path, ...path.split('/')]))
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }
  return Repo(dir.path);
}

/// Spec de widget completa, com todas as etiquetas obrigatórias.
///
/// [dependencies] entram no requisito `[Integração]`; [omit] remove etiquetas.
String widgetSpec({
  List<String> dependencies = const [],
  Set<String> omit = const {},
  bool purpose = true,
}) {
  final buffer = StringBuffer('# Spec Delta\n\n');
  if (purpose) {
    buffer.writeln('## Purpose\n\nWidget de exemplo usado nos testes das verificações.\n');
  }
  buffer.writeln('## ADDED Requirements\n');
  for (final tag in requiredWidgetTags) {
    if (omit.contains(tag)) continue;
    final body = tag == 'Integração'
        ? 'O widget SHALL depender somente de: ${dependencies.map((d) => '`$d`').join(', ')}.'
        : 'O widget SHALL atender ao aspecto $tag.';
    buffer.writeln('### Requirement: [$tag] Requisito\n$body\n');
    buffer.writeln('#### Scenario: Cenário\n- **WHEN** algo ocorre\n- **THEN** algo é verificado\n');
  }
  return buffer.toString();
}

/// Spec de fundamento/núcleo que referencia [dependencies].
String componentSpec({List<String> dependencies = const []}) => '''
# Spec Delta

## Purpose

Fundamento de exemplo usado nos testes das verificações.

## ADDED Requirements

### Requirement: Base
O fundamento SHALL existir. Dependências: ${dependencies.map((d) => '`$d`').join(', ')}.

#### Scenario: Cenário
- **WHEN** algo ocorre
- **THEN** algo é verificado
''';

/// Mensagens das violações, para asserções legíveis.
List<String> messages(List<Violation> violations) => [for (final v in violations) v.toString()];
