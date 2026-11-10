import 'dart:io';

import 'package:path/path.dart' as p;

/// Pacotes do framework em ordem de camada: um pacote só pode depender de
/// pacotes com índice menor.
const frameworkLayers = [
  'gja_foundation',
  'gja_core',
  'gja_widgets',
  'gja_ui',
];

/// Profundidade, abaixo de `lib/src`, que define um módulo interno de cada
/// pacote (para `gja_widgets`: `<categoria>/<widget>`).
const moduleDepth = {'gja_widgets': 2};

/// Acesso aos arquivos de um repositório GJA a partir da sua raiz.
class Repo {
  /// Cria o acesso ao repositório com raiz em [root].
  Repo(String root) : root = p.normalize(p.absolute(root));

  /// Caminho absoluto da raiz do repositório.
  final String root;

  /// Localiza a raiz subindo a partir de [start] até encontrar um diretório
  /// com `openspec/` e `pubspec.yaml`.
  static Repo? find(String start) {
    var dir = p.normalize(p.absolute(start));
    while (true) {
      if (Directory(p.join(dir, 'openspec')).existsSync() &&
          File(p.join(dir, 'pubspec.yaml')).existsSync()) {
        return Repo(dir);
      }
      final parent = p.dirname(dir);
      if (parent == dir) return null;
      dir = parent;
    }
  }

  /// Caminho absoluto de [relative] (separado por `/`) dentro da raiz.
  String path(String relative) => p.joinAll([root, ...relative.split('/')]);

  /// Caminho de [absolute] relativo à raiz, separado por `/`.
  String relative(String absolute) =>
      p.relative(absolute, from: root).replaceAll(r'\', '/');

  /// Arquivos `.dart` sob [relativeDir], em ordem estável.
  List<File> dartFiles(String relativeDir) {
    final dir = Directory(path(relativeDir));
    if (!dir.existsSync()) return const [];
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }
}
