import 'dart:io';

import 'package:yaml/yaml.dart';

import 'graph.dart';
import 'repo.dart';
import 'specs_check.dart';
import 'violation.dart';

const _check = 'catalog';

/// Arquivo do catálogo de componentes (fonte da verdade).
const catalogFile = 'docs/catalog.yaml';

const _kinds = {'widget': 'gja/widgets/', 'foundation': 'gja/foundation/', 'core': 'gja/core/'};
const _priorities = ['P0', 'P1', 'P2', 'P3'];
const _statuses = {'planned', 'specified', 'implemented', 'deprecated'};

/// Um item do catálogo.
class CatalogItem {
  /// Cria o item [id].
  const CatalogItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.category,
    required this.priority,
    required this.phase,
    required this.status,
    required this.dependsOn,
  });

  /// Caminho da spec (por exemplo, `gja/widgets/gja-button`).
  final String id;

  /// Nome público (por exemplo, `GjaButton`).
  final String name;

  /// `widget`, `foundation` ou `core`.
  final String kind;

  /// Categoria em kebab-case; para widgets, define a pasta em `lib/src`.
  final String category;

  /// Prioridade `P0` a `P3`.
  final String priority;

  /// Fase de implementação (1 a 5).
  final int phase;

  /// `planned`, `specified`, `implemented` ou `deprecated`.
  final String status;

  /// Ids das specs das quais o item depende.
  final List<String> dependsOn;

  /// Pasta esperada do widget implementado, relativa à raiz.
  String get widgetDirectory {
    final widget = id.substring('gja/widgets/gja-'.length).replaceAll('-', '_');
    return 'packages/gja_widgets/lib/src/${category.replaceAll('-', '_')}/$widget';
  }
}

/// Lê o catálogo, retornando os itens válidos e as violações de formato.
(List<CatalogItem>, List<Violation>) loadCatalog(Repo repo) {
  final file = File(repo.path(catalogFile));
  if (!file.existsSync()) {
    return (const [], [const Violation(_check, catalogFile, 'catálogo não encontrado')]);
  }
  final violations = <Violation>[];
  final Object? yaml;
  try {
    yaml = loadYaml(file.readAsStringSync());
  } on YamlException catch (e) {
    return (const [], [Violation(_check, catalogFile, 'YAML inválido: ${e.message}')]);
  }
  final entries = yaml is YamlMap ? yaml['items'] : null;
  if (entries is! YamlList) {
    return (const [], [const Violation(_check, catalogFile, '"items" deve ser uma lista')]);
  }
  final items = <CatalogItem>[];
  for (final (index, entry) in entries.indexed) {
    final label = entry is YamlMap && entry['id'] is String ? entry['id'] as String : '#${index + 1}';
    void fail(String message) => violations.add(Violation(_check, catalogFile, '$label: $message'));
    if (entry is! YamlMap) {
      fail('item deve ser um mapa');
      continue;
    }
    final id = entry['id'], name = entry['name'], kind = entry['kind'];
    final category = entry['category'], priority = entry['priority'];
    final phase = entry['phase'], status = entry['status'];
    final dependsOn = entry['depends_on'] ?? YamlList();
    if (id is! String || !componentSpecId.hasMatch(id)) {
      fail('"id" deve ser um caminho de spec gja/(widgets|foundation|core)/<kebab-case>');
      continue;
    }
    if (name is! String || name.isEmpty) fail('"name" obrigatório');
    if (kind is! String || !_kinds.containsKey(kind)) {
      fail('"kind" deve ser ${_kinds.keys.join(', ')}');
    } else if (!id.startsWith(_kinds[kind]!)) {
      fail('"kind: $kind" não corresponde ao caminho do id');
    }
    if (category is! String || !RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(category)) {
      fail('"category" deve ser kebab-case');
    }
    if (priority is! String || !_priorities.contains(priority)) {
      fail('"priority" deve ser ${_priorities.join(', ')}');
    }
    if (phase is! int || phase < 1 || phase > 5) fail('"phase" deve ser um inteiro de 1 a 5');
    if (status is! String || !_statuses.contains(status)) {
      fail('"status" deve ser ${_statuses.join(', ')}');
    }
    if (dependsOn is! YamlList || dependsOn.any((d) => d is! String)) {
      fail('"depends_on" deve ser uma lista de ids');
    }
    if (name is String && kind is String && _kinds.containsKey(kind) && category is String &&
        priority is String && _priorities.contains(priority) && phase is int &&
        status is String && dependsOn is YamlList) {
      items.add(CatalogItem(
        id: id,
        name: name,
        kind: kind,
        category: category,
        priority: priority,
        phase: phase,
        status: status,
        dependsOn: dependsOn.cast<String>().toList(),
      ));
    }
  }
  return (items, violations);
}

/// Verifica a coerência do catálogo com as specs e com o código.
List<Violation> checkCatalog(Repo repo) {
  final (items, violations) = loadCatalog(repo);
  void fail(String message) => violations.add(Violation(_check, catalogFile, message));

  final byId = <String, CatalogItem>{};
  for (final item in items) {
    if (byId.containsKey(item.id)) fail('${item.id}: id duplicado');
    byId[item.id] = item;
  }

  final main = loadMainSpecs(repo);
  final changeSpecs = loadChangeSpecs(repo);
  final inChanges = {for (final s in changeSpecs) s.id};
  // Dependências declaradas nas changes ativas (ex.: um MODIFIED de
  // [Integração]) valem como as da spec principal, como no grafo de specs.
  final changeDependencies = <String, Set<String>>{};
  for (final spec in changeSpecs) {
    (changeDependencies[spec.id] ??= {}).addAll(spec.dependencies);
  }

  for (final item in items) {
    for (final dep in item.dependsOn) {
      final target = byId[dep];
      if (target == null) {
        fail('${item.id}: dependência "$dep" não está no catálogo');
        continue;
      }
      if (_priorities.indexOf(item.priority) < _priorities.indexOf(target.priority)) {
        fail('${item.id}: prioridade ${item.priority} mais urgente que a dependência $dep (${target.priority})');
      }
      if (item.phase < target.phase) {
        fail('${item.id}: fase ${item.phase} anterior à da dependência $dep (fase ${target.phase})');
      }
    }

    final hasSpec = main.containsKey(item.id);
    if (item.status != 'planned' && !hasSpec && !inChanges.contains(item.id)) {
      fail('${item.id}: situação "${item.status}" exige spec em openspec/specs/${item.id} ou em change ativa');
    }
    if (item.status == 'planned' && hasSpec) {
      fail('${item.id}: possui spec principal, mas está como "planned"');
    }
    if (hasSpec) {
      final declared = {
        ...main[item.id]!.dependencies,
        ...?changeDependencies[item.id],
      };
      for (final dep in item.dependsOn) {
        if (!declared.contains(dep)) {
          fail('${item.id}: dependência "$dep" do catálogo não aparece na spec');
        }
      }
    }
    if (item.kind == 'widget' && item.status == 'implemented' &&
        !Directory(repo.path(item.widgetDirectory)).existsSync()) {
      fail('${item.id}: implementado, mas a pasta ${item.widgetDirectory} não existe');
    }
  }

  // Uma spec principal que uma change ativa está retirando já saiu do catálogo.
  final retired = retiredCapabilities(repo);
  for (final id in main.keys) {
    if (!byId.containsKey(id) && !retired.contains(id)) {
      fail('$id: spec existe em openspec/specs, mas não está no catálogo');
    }
  }

  final edges = {for (final item in items) item.id: item.dependsOn.toSet()};
  for (final cycle in findCycles(edges)) {
    fail('ciclo de dependências no catálogo: ${cycle.join(' -> ')}');
  }
  return violations;
}
