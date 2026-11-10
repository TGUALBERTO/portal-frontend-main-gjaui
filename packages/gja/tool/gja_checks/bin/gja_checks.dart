import 'dart:io';

import 'package:gja_checks/gja_checks.dart';

const _usage = '''
Uso: dart run gja_checks <verificação> [--root <diretório>]

Verificações:
  architecture  imports entre camadas, Material/Cupertino e API pública
  tokens        valores visuais literais em packages/gja_widgets/lib
  specs         estrutura, referências e ciclos das specs de componente
  catalog       coerência de docs/catalog.yaml com specs e código
  all           todas as anteriores

Saída: 0 sem violações, 1 com violações, 64 em uso incorreto.''';

Future<void> main(List<String> args) async {
  final positional = <String>[];
  String? root;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--root' && i + 1 < args.length) {
      root = args[++i];
    } else if (args[i] == '-h' || args[i] == '--help') {
      stdout.writeln(_usage);
      return;
    } else {
      positional.add(args[i]);
    }
  }
  const checks = ['architecture', 'tokens', 'specs', 'catalog'];
  if (positional.length != 1 || !(checks.contains(positional.single) || positional.single == 'all')) {
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }
  final repo = root != null ? Repo(root) : Repo.find(Directory.current.path);
  if (repo == null) {
    stderr.writeln('Raiz do repositório não encontrada (diretório com openspec/ e pubspec.yaml).');
    exitCode = 64;
    return;
  }

  final selected = positional.single == 'all' ? checks : [positional.single];
  var total = 0;
  for (final check in selected) {
    final violations = switch (check) {
      'architecture' => [...checkImports(repo), ...await checkPublicApi(repo)],
      'tokens' => checkTokens(repo),
      'specs' => checkSpecs(repo),
      _ => checkCatalog(repo),
    };
    total += violations.length;
    stdout.writeln(violations.isEmpty ? '✓ $check' : '✗ $check (${violations.length})');
    for (final violation in violations) {
      stdout.writeln('  $violation');
    }
  }
  if (total > 0) exitCode = 1;
}
