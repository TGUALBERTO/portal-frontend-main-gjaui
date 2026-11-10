import 'dart:io';

/// Raiz do repositório, a partir do diretório do pacote.
Directory get repoRoot => Directory.current.parent.parent;

/// Nomes no formato `<requisito> — <cenário>` da spec [id]: a principal com
/// os requisitos ADDED e MODIFIED das changes ativas aplicados por cima e os
/// REMOVED retirados.
///
/// [change] é a change que criou a spec; outras changes ativas que a
/// modificam também são consideradas, para que os nomes reflitam a spec como
/// ficará após o arquivamento.
List<String> scenarioNames(String id, String change) {
  final main = File('${repoRoot.path}/openspec/specs/$id/spec.md');
  final changes = Directory('${repoRoot.path}/openspec/changes');
  final dirs = [
    for (final dir in changes.listSync().whereType<Directory>())
      if (dir.uri.pathSegments.lastWhere((s) => s.isNotEmpty) != 'archive') dir,
  ];
  // A change que criou a spec vem primeiro; as que a modificam, depois.
  bool creator(Directory d) =>
      d.uri.pathSegments.lastWhere((s) => s.isNotEmpty) == change;
  dirs.sort((a, b) => (creator(a) ? 0 : 1) - (creator(b) ? 0 : 1));
  final deltas = [
    for (final dir in dirs) File('${dir.path}/specs/$id/spec.md'),
  ].where((f) => f.existsSync());
  final requirements = <String, List<String>>{
    if (main.existsSync()) ..._requirements(main).kept,
  };
  for (final delta in deltas) {
    final (:kept, :removed) = _requirements(delta);
    requirements
      ..addAll(kept)
      ..removeWhere((name, _) => removed.contains(name));
  }
  return [
    for (final MapEntry(key: requirement, value: scenarios)
        in requirements.entries)
      for (final scenario in scenarios) '$requirement — $scenario',
  ];
}

/// Cenários de cada requisito de [spec], na ordem do arquivo (`kept`), e os
/// nomes dos requisitos em `## REMOVED Requirements` (`removed`).
({Map<String, List<String>> kept, Set<String> removed}) _requirements(
  File spec,
) {
  final result = <String, List<String>>{};
  final removed = <String>{};
  var removing = false;
  String? requirement;
  for (final line in spec.readAsLinesSync()) {
    if (line.startsWith('## ')) removing = line.startsWith('## REMOVED');
    final req = RegExp(r'^### Requirement: (.+)$').firstMatch(line);
    if (req != null) {
      requirement = req.group(1)!.trim();
      if (removing) {
        removed.add(requirement);
        requirement = null;
      } else {
        result[requirement] = [];
      }
    }
    final scen = RegExp(r'^#### Scenario: (.+)$').firstMatch(line);
    if (scen != null && requirement != null) {
      result[requirement]!.add(scen.group(1)!.trim());
    }
  }
  return (kept: result, removed: removed);
}

/// Cenários de [names] sem teste de mesmo nome nas suítes de `gja_widgets`
/// e da galeria.
List<String> untestedScenarios(List<String> names) {
  final tests = [
    for (final dir in [
      Directory('${repoRoot.path}/packages/gja_widgets/test'),
      Directory('${repoRoot.path}/apps/gja_gallery/test'),
    ])
      for (final f in dir.listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('_test.dart')) f.readAsStringSync(),
  ].join('\n');
  return [
    for (final name in names)
      if (!tests.contains("'$name'")) name,
  ];
}
