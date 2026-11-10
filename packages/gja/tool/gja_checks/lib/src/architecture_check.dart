import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as p;

import 'graph.dart';
import 'repo.dart';
import 'violation.dart';

const _check = 'architecture';

final _directive = RegExp(r'''^\s*(import|export)\s+['"]([^'"]+)['"](.*)$''');
final _adrMarker = RegExp(r'//\s*gja-adr:\s*(\d{4})');
final _foundationInternals = RegExp(
  r'^package:gja_foundation/(gja_primitives\.dart$|src/)',
);
final _forbiddenUi = RegExp(
  r'^package:flutter/(material|cupertino)\.dart$|'
  r'^package:flutter/src/(material|cupertino)/',
);

/// Verifica imports entre camadas, imports de Material/Cupertino sem ADR,
/// acesso aos primitivos e a `src/` de `gja_foundation` fora do próprio
/// pacote e ciclos entre módulos internos de cada pacote do framework.
List<Violation> checkImports(Repo repo) {
  final violations = <Violation>[];
  for (final (layer, package) in frameworkLayers.indexed) {
    final libDir = 'packages/$package/lib';
    final moduleEdges = <String, Set<String>>{};
    for (final file in repo.dartFiles(libDir)) {
      final rel = repo.relative(file.path);
      final fromModule = _moduleOf(package, p.relative(file.path, from: repo.path(libDir)));
      final lines = file.readAsLinesSync();
      for (final (index, line) in lines.indexed) {
        final match = _directive.firstMatch(line);
        if (match == null) continue;
        final kind = match.group(1)!;
        final uri = match.group(2)!;
        final rest = match.group(3)!;
        final lineNo = index + 1;

        if (_forbiddenUi.hasMatch(uri)) {
          if (kind == 'export') {
            violations.add(Violation(_check, rel,
                'reexporta "$uri"; a API pública não pode expor Material/Cupertino (ADR 0004)',
                line: lineNo));
          } else if (!_hasAcceptedAdr(repo, rest)) {
            violations.add(Violation(_check, rel,
                'importa "$uri" sem marcador "// gja-adr: NNNN" apontando para uma ADR existente (ADR 0004)',
                line: lineNo));
          }
          continue;
        }

        if (package != 'gja_foundation' && _foundationInternals.hasMatch(uri)) {
          violations.add(Violation(_check, rel,
              '$kind de "$uri": primitivos e src/ de gja_foundation são restritos ao próprio pacote (ADR 0005)',
              line: lineNo));
          continue;
        }

        final target = _packageOf(uri);
        if (target != null && target != package) {
          final targetLayer = frameworkLayers.indexOf(target);
          if (targetLayer > layer) {
            violations.add(Violation(_check, rel,
                '$package (camada $layer) não pode depender de $target (camada $targetLayer)',
                line: lineNo));
          }
          continue;
        }

        // Aresta entre módulos internos do mesmo pacote.
        if (fromModule == null) continue;
        final String targetPath;
        if (target == package) {
          targetPath = uri.substring('package:$package/'.length);
        } else if (!uri.contains(':')) {
          targetPath = p.posix.normalize(p.posix.join(
              p.posix.dirname(p.relative(file.path, from: repo.path(libDir)).replaceAll(r'\', '/')),
              uri));
        } else {
          continue;
        }
        final toModule = _moduleOf(package, targetPath);
        if (toModule != null && toModule != fromModule) {
          moduleEdges.putIfAbsent(fromModule, () => {}).add(toModule);
        }
      }
    }
    for (final cycle in findCycles(moduleEdges)) {
      violations.add(Violation(_check, libDir,
          'ciclo entre módulos internos: ${cycle.join(' -> ')}'));
    }
  }
  return violations;
}

/// Pacote GJA referenciado por [uri], ou `null` se não for um pacote do
/// framework.
String? _packageOf(String uri) {
  if (!uri.startsWith('package:')) return null;
  final name = uri.substring('package:'.length).split('/').first;
  return frameworkLayers.contains(name) ? name : null;
}

/// Módulo interno de um arquivo (caminho relativo a `lib/`), ou `null` para
/// bibliotecas públicas fora de `lib/src`.
String? _moduleOf(String package, String libRelative) {
  final segments = libRelative.replaceAll(r'\', '/').split('/');
  if (segments.length < 3 || segments.first != 'src') return null;
  final depth = moduleDepth[package] ?? 1;
  final dirs = segments.sublist(1, segments.length - 1);
  if (dirs.isEmpty) return 'src';
  return dirs.take(depth).join('/');
}

bool _hasAcceptedAdr(Repo repo, String rest) {
  final match = _adrMarker.firstMatch(rest);
  if (match == null) return false;
  final dir = Directory(repo.path('docs/adr'));
  if (!dir.existsSync()) return false;
  final prefix = '${match.group(1)}-';
  return dir
      .listSync()
      .whereType<File>()
      .any((f) => p.basename(f.path).startsWith(prefix));
}

/// Verifica, com o analisador do Dart, se algum símbolo exportado pelas
/// bibliotecas públicas (`lib/*.dart`) dos pacotes do framework referencia
/// tipos de Material ou Cupertino.
Future<List<Violation>> checkPublicApi(Repo repo) async {
  final libraries = <String>[
    for (final package in frameworkLayers)
      for (final file in repo.dartFiles('packages/$package/lib'))
        if (p.dirname(file.path) == repo.path('packages/$package/lib'))
          p.normalize(file.path),
  ];
  if (libraries.isEmpty) return const [];

  final collection = AnalysisContextCollection(includedPaths: libraries);
  final violations = <Violation>[];
  for (final library in libraries) {
    final session = collection.contextFor(library).currentSession;
    final result = await session.getResolvedLibrary(library);
    if (result is! ResolvedLibraryResult) {
      violations.add(Violation(_check, repo.relative(library),
          'não foi possível resolver a biblioteca ($result)'));
      continue;
    }
    final names = result.element2.exportNamespace.definedNames2;
    for (final MapEntry(key: name, value: element) in names.entries) {
      final leaks = <String>{};
      _collectElement(element, leaks);
      for (final leak in leaks) {
        violations.add(Violation(_check, repo.relative(library),
            'símbolo exportado "$name" referencia $leak (ADR 0004)'));
      }
    }
  }
  await collection.dispose();
  return violations;
}

bool _isForbiddenLibrary(LibraryElement2? library) {
  if (library == null) return false;
  return _forbiddenUi.hasMatch(library.uri.toString());
}

void _collectElement(Element2 element, Set<String> leaks) {
  if (_isForbiddenLibrary(element.library2)) {
    leaks.add('${element.displayName} (${element.library2!.uri})');
    return;
  }
  switch (element) {
    case InterfaceElement2():
      for (final type in [
        ?element.supertype,
        ...element.interfaces,
        ...element.mixins,
        if (element is MixinElement2) ...element.superclassConstraints,
      ]) {
        _collectType(type, leaks);
      }
      _collectTypeParameters(element.typeParameters2, leaks);
      for (final constructor in element.constructors2) {
        if (constructor.isPublic) _collectType(constructor.type, leaks);
      }
      _collectMembers(element, leaks);
    case ExtensionElement2():
      _collectType(element.extendedType, leaks);
      _collectTypeParameters(element.typeParameters2, leaks);
      _collectMembers(element, leaks);
    case TypeAliasElement2():
      _collectTypeParameters(element.typeParameters2, leaks);
      _collectType(element.aliasedType, leaks);
    case ExecutableElement2():
      _collectType(element.type, leaks);
    case PropertyInducingElement2():
      _collectType(element.type, leaks);
    default:
      break;
  }
}

void _collectMembers(InstanceElement2 element, Set<String> leaks) {
  for (final method in element.methods2) {
    if (method.isPublic) _collectType(method.type, leaks);
  }
  for (final accessor in [...element.getters2, ...element.setters2]) {
    if (accessor.isPublic) _collectType(accessor.type, leaks);
  }
  for (final field in element.fields2) {
    if (field.isPublic) _collectType(field.type, leaks);
  }
}

void _collectTypeParameters(
    List<TypeParameterElement2> parameters, Set<String> leaks) {
  for (final parameter in parameters) {
    final bound = parameter.bound;
    if (bound != null) _collectType(bound, leaks);
  }
}

void _collectType(DartType type, Set<String> leaks, [Set<DartType>? seen]) {
  seen ??= {};
  if (!seen.add(type)) return;
  final alias = type.alias;
  if (alias != null && _isForbiddenLibrary(alias.element2.library2)) {
    leaks.add('${alias.element2.displayName} (${alias.element2.library2.uri})');
  }
  switch (type) {
    case InterfaceType():
      if (_isForbiddenLibrary(type.element3.library2)) {
        leaks.add('${type.element3.displayName} (${type.element3.library2.uri})');
      }
      for (final argument in type.typeArguments) {
        _collectType(argument, leaks, seen);
      }
    case FunctionType():
      _collectType(type.returnType, leaks, seen);
      for (final parameter in type.formalParameters) {
        _collectType(parameter.type, leaks, seen);
      }
      for (final parameter in type.typeParameters) {
        final bound = parameter.bound;
        if (bound != null) _collectType(bound, leaks, seen);
      }
    case RecordType():
      for (final field in type.positionalFields) {
        _collectType(field.type, leaks, seen);
      }
      for (final field in type.namedFields) {
        _collectType(field.type, leaks, seen);
      }
    default:
      break;
  }
}
