import 'dart:io';

import 'package:yaml/yaml.dart';

import 'repo.dart';
import 'violation.dart';

const _check = 'tokens';

/// Diretório verificado: código dos widgets públicos.
const tokensScope = 'packages/gja_widgets/lib';

/// Arquivo versionado de exceções justificadas.
const tokenExceptionsFile = 'tool/gja_checks/token_exceptions.yaml';

// Número literal que não faz parte de um identificador nem de um acesso.
const _number = r'(?<![\w.])\d+(?:\.\d+)?';

/// Padrões de valores visuais literais proibidos nos widgets (ADR 0005).
final tokenPatterns = <String, RegExp>{
  'cor literal': RegExp(r'\bColor(?:\.fromARGB|\.fromRGBO)?\s*\(|\bColors\.'),
  'espaçamento literal': RegExp(r'\bEdgeInsets(?:Directional)?\.\w+\([^)]*' '$_number'),
  'raio literal': RegExp(
      r'\b(?:BorderRadius(?:Directional)?\.\w+\([^)]*|Radius\.(?:circular|elliptical)\(\s*)'
          '$_number'),
  'duração literal': RegExp(r'\bDuration\s*\(\s*\w+\s*:\s*' '$_number'),
  'estilo de texto literal': RegExp(
      r'\bTextStyle\s*\([^)]*\b(?:fontSize|height|letterSpacing|wordSpacing)\s*:\s*' '$_number'),
  'dimensão literal': RegExp(
      r'\b(?:width|height|size|elevation|blurRadius|spreadRadius|thickness|'
      r'strokeWidth|radius|spacing|runSpacing|gap|minWidth|minHeight|maxWidth|maxHeight)'
      r'\s*:\s*(?!0(?:\.0)?\b)' '$_number'),
};

/// Exceção justificada a uma regra de tokens.
class TokenException {
  /// Cria a exceção para linhas de [file] que contêm [contains].
  const TokenException(this.file, this.contains, this.reason);

  /// Arquivo relativo à raiz, separado por `/`.
  final String file;

  /// Trecho exato que a linha precisa conter.
  final String contains;

  /// Justificativa obrigatória.
  final String reason;
}

/// Lê as exceções de [repo], validando que cada uma tenha justificativa.
(List<TokenException>, List<Violation>) loadTokenExceptions(Repo repo) {
  final file = File(repo.path(tokenExceptionsFile));
  if (!file.existsSync()) return (<TokenException>[], <Violation>[]);
  final yaml = loadYaml(file.readAsStringSync());
  final entries = yaml is YamlMap ? yaml['exceptions'] : null;
  final exceptions = <TokenException>[];
  final violations = <Violation>[];
  if (entries == null) return (exceptions, violations);
  if (entries is! YamlList) {
    return (exceptions, <Violation>[Violation(_check, tokenExceptionsFile, '"exceptions" deve ser uma lista')]);
  }
  for (final (index, entry) in entries.indexed) {
    final fileName = entry is YamlMap ? entry['file'] : null;
    final contains = entry is YamlMap ? entry['contains'] : null;
    final reason = entry is YamlMap ? entry['reason'] : null;
    if (fileName is! String || contains is! String || reason is! String || reason.trim().isEmpty) {
      violations.add(Violation(_check, tokenExceptionsFile,
          'exceção #${index + 1} precisa de "file", "contains" e "reason" não vazio'));
      continue;
    }
    exceptions.add(TokenException(fileName, contains, reason));
  }
  return (exceptions, violations);
}

/// Procura valores visuais literais no código dos widgets.
List<Violation> checkTokens(Repo repo) {
  final (exceptions, violations) = loadTokenExceptions(repo);
  var inBlockComment = false;
  for (final file in repo.dartFiles(tokensScope)) {
    final rel = repo.relative(file.path);
    final fileExceptions = exceptions.where((e) => e.file == rel).toList();
    for (final (index, raw) in file.readAsLinesSync().indexed) {
      var line = raw;
      if (inBlockComment) {
        final end = line.indexOf('*/');
        if (end < 0) continue;
        inBlockComment = false;
        line = line.substring(end + 2);
      }
      final blockStart = line.indexOf('/*');
      if (blockStart >= 0) {
        if (!line.contains('*/', blockStart)) inBlockComment = true;
        line = line.substring(0, blockStart);
      }
      final comment = line.indexOf('//');
      if (comment >= 0) line = line.substring(0, comment);
      if (line.trim().isEmpty) continue;
      if (fileExceptions.any((e) => raw.contains(e.contains))) continue;
      for (final MapEntry(key: name, value: pattern) in tokenPatterns.entries) {
        if (pattern.hasMatch(line)) {
          violations.add(Violation(_check, rel,
              '$name: use tokens do tema em vez de "${line.trim()}" (ADR 0005)',
              line: index + 1));
        }
      }
    }
    inBlockComment = false;
  }
  return violations;
}
