import 'dart:io';

import 'package:path/path.dart' as p;

import 'graph.dart';
import 'repo.dart';
import 'violation.dart';

const _check = 'specs';

/// Etiquetas obrigatórias dos requisitos de uma spec de widget
/// (spec `gja/spec-governance`, requisito "Mapeamento das seções
/// obrigatórias").
const requiredWidgetTags = [
  'API',
  'Comportamento',
  'Aparência',
  'Estados',
  'Acessibilidade',
  'Responsividade',
  'Integração',
  'Testes',
  'Documentação',
  'Restrições',
];

/// Identificador de spec de componente (widget, fundamento ou núcleo).
final componentSpecId = RegExp(r'^gja/(widgets|foundation|core)/[a-z0-9]+(?:-[a-z0-9]+)*$');

final _reference = RegExp(r'gja/(?:widgets|foundation|core)/[a-z0-9]+(?:-[a-z0-9]+)*');
final _requirement = RegExp(r'^###\s+Requirement:\s*(.+?)\s*$');
final _tag = RegExp(r'^\[([^\]]+)\]');

/// Um requisito de uma spec.
class SpecRequirement {
  /// Cria o requisito [title] com corpo [body], iniciado na linha [line].
  const SpecRequirement(this.title, this.body, this.line);

  /// Título após `### Requirement:`.
  final String title;

  /// Texto do requisito, incluindo cenários.
  final String body;

  /// Linha do cabeçalho (base 1).
  final int line;

  /// Etiqueta entre colchetes no início do título, se houver.
  String? get tag => _tag.firstMatch(title)?.group(1);
}

/// Uma spec de componente encontrada no repositório.
class SpecFile {
  /// Cria a spec [id] lida de [path].
  SpecFile(this.id, this.path, this.text, {this.change});

  /// Caminho da capacidade (por exemplo, `gja/widgets/gja-button`).
  final String id;

  /// Caminho do arquivo relativo à raiz.
  final String path;

  /// Conteúdo do arquivo.
  final String text;

  /// Change ativa que contém a spec, ou `null` para spec principal.
  final String? change;

  /// Se a spec descreve um widget público.
  bool get isWidget => id.startsWith('gja/widgets/');

  /// Se a spec contém a seção `## Purpose`.
  bool get hasPurpose => RegExp(r'^##\s+Purpose\s*$', multiLine: true).hasMatch(text);

  /// Requisitos da spec, em ordem.
  late final List<SpecRequirement> requirements = _parseRequirements();

  /// Specs de componente das quais esta depende.
  ///
  /// Para widgets, somente as referências em requisitos `[Integração]`; para
  /// fundamentos e núcleo, todas as referências do arquivo.
  Set<String> get dependencies {
    final source = isWidget
        ? requirements.where((r) => r.tag == 'Integração').map((r) => r.body).join('\n')
        : text;
    return {for (final m in _reference.allMatches(source)) m.group(0)!}..remove(id);
  }

  /// Todas as referências a specs de componente no arquivo, com a linha.
  Iterable<(String, int)> get references sync* {
    for (final (index, line) in text.split('\n').indexed) {
      for (final match in _reference.allMatches(line)) {
        if (match.group(0) != id) yield (match.group(0)!, index + 1);
      }
    }
  }

  List<SpecRequirement> _parseRequirements() {
    final lines = text.split('\n');
    final result = <SpecRequirement>[];
    for (var i = 0; i < lines.length; i++) {
      final match = _requirement.firstMatch(lines[i]);
      if (match == null) continue;
      var end = i + 1;
      while (end < lines.length &&
          !lines[end].startsWith('### ') &&
          !RegExp(r'^##\s').hasMatch(lines[end])) {
        end++;
      }
      result.add(SpecRequirement(match.group(1)!, lines.sublist(i + 1, end).join('\n'), i + 1));
    }
    return result;
  }
}

/// Specs principais de componente (`openspec/specs/gja/...`), por id.
Map<String, SpecFile> loadMainSpecs(Repo repo) => {
      for (final spec in _specsUnder(repo, 'openspec/specs', null)) spec.id: spec,
    };

/// Specs de componente nas changes ativas (fora de `archive`).
List<SpecFile> loadChangeSpecs(Repo repo) {
  final changes = Directory(repo.path('openspec/changes'));
  if (!changes.existsSync()) return const [];
  final result = <SpecFile>[];
  final dirs = changes.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final dir in dirs) {
    final name = p.basename(dir.path);
    if (name == 'archive') continue;
    result.addAll(_specsUnder(repo, 'openspec/changes/$name/specs', name));
  }
  return result;
}

/// Capacidades retiradas por changes ativas.
///
/// Uma capacidade é retirada quando a change declara `retire_capabilities: true`
/// no `.openspec.yaml` e o delta dela só tem `## REMOVED Requirements`. A spec
/// principal continua existindo até o arquivamento.
Set<String> retiredCapabilities(Repo repo) {
  final result = <String>{};
  final retiring = RegExp(r'^retire_capabilities:\s*true\s*$', multiLine: true);
  final section = RegExp(r'^##\s+(ADDED|MODIFIED|REMOVED|RENAMED)\s+Requirements\s*$', multiLine: true);
  for (final spec in loadChangeSpecs(repo)) {
    final config = File(repo.path('openspec/changes/${spec.change}/.openspec.yaml'));
    if (!config.existsSync() || !retiring.hasMatch(config.readAsStringSync())) continue;
    final sections = {for (final m in section.allMatches(spec.text)) m.group(1)};
    if (sections.length == 1 && sections.single == 'REMOVED') result.add(spec.id);
  }
  return result;
}

Iterable<SpecFile> _specsUnder(Repo repo, String relativeRoot, String? change) sync* {
  final root = Directory(repo.path(relativeRoot));
  if (!root.existsSync()) return;
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => p.basename(f.path) == 'spec.md')
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final id = p.relative(p.dirname(file.path), from: root.path).replaceAll(r'\', '/');
    if (!componentSpecId.hasMatch(id)) continue;
    yield SpecFile(id, repo.relative(file.path), file.readAsStringSync(), change: change);
  }
}

/// Verifica estrutura, referências e ciclos das specs de componente.
List<Violation> checkSpecs(Repo repo) {
  final main = loadMainSpecs(repo);
  final changeSpecs = loadChangeSpecs(repo);
  final violations = <Violation>[];

  for (final spec in [...main.values, ...changeSpecs]) {
    // Deltas de capacidade existente (MODIFIED etc.) não repetem a estrutura.
    final isNewOrMain = spec.change == null || !main.containsKey(spec.id);
    if (spec.isWidget && isNewOrMain) {
      if (!spec.hasPurpose) {
        violations.add(Violation(_check, spec.path, 'falta a seção "## Purpose" (Objetivo e escopo)'));
      }
      final tags = {for (final r in spec.requirements) r.tag};
      for (final tag in requiredWidgetTags) {
        if (!tags.contains(tag)) {
          violations.add(Violation(_check, spec.path, 'falta requisito com a etiqueta [$tag]'));
        }
      }
    }

    final sameChange = {
      for (final s in changeSpecs)
        if (spec.change != null && s.change == spec.change) s.id,
    };
    for (final (reference, line) in spec.references) {
      if (main.containsKey(reference) || sameChange.contains(reference)) continue;
      violations.add(Violation(_check, spec.path,
          'referencia "$reference", que não existe em openspec/specs nem na mesma change',
          line: line));
    }
  }

  // Grafo efetivo: specs principais sobrepostas pelas das changes ativas.
  final edges = <String, Set<String>>{
    for (final spec in main.values) spec.id: spec.dependencies,
  };
  for (final spec in changeSpecs) {
    (edges[spec.id] ??= {}).addAll(spec.dependencies);
  }
  for (final cycle in findCycles(edges)) {
    violations.add(Violation(_check, 'openspec', 'ciclo de dependências entre specs: ${cycle.join(' -> ')}'));
  }
  return violations;
}
