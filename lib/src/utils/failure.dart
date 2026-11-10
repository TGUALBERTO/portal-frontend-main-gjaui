import 'package:equatable/equatable.dart';

/// Base failure type used across the app. Extends [Exception] so it satisfies
/// `result_dart` Failure bounds while remaining value-equal via [Equatable].
abstract class AppFailure extends Equatable implements Exception {
  final String message;
  final Object? cause;

  const AppFailure(this.message, {this.cause});

  @override
  List<Object?> get props => [message, cause];

  @override
  String toString() => '$runtimeType($message)';
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.cause});
}

class ServerFailure extends AppFailure {
  const ServerFailure(super.message, {super.cause});
}

/// Falha mapeada de uma resposta de erro da API, opcionalmente no formato
/// RFC 7807 (`application/problem+json`): `{ type, title, status, detail }`.
///
/// [status] é o código HTTP (ex.: 404, 409, 502); [title]/[detail] vêm do corpo
/// `problem+json` quando presentes. Usada por features que precisam reagir ao
/// código HTTP (ex.: TeamsBot/ATAs). É uma [AppFailure], então é
/// retrocompatível com quem só lê `.message`.
class ApiFailure extends AppFailure {
  final int? status;
  final String? title;
  final String? detail;

  /// Código de erro legível por máquina emitido pelo backend
  /// (error-handling-spring-boot-starter), ex.: `KBA_CPF_NOT_FOUND`.
  /// Nulo quando o corpo de erro não traz `code`.
  final String? code;

  const ApiFailure(
    super.message, {
    this.status,
    this.title,
    this.detail,
    this.code,
    super.cause,
  });

  bool get isNotFound => status == 404;
  bool get isConflict => status == 409;
  bool get isBadGateway => status == 502;

  @override
  List<Object?> get props => [message, status, title, detail, code, cause];
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {super.cause});
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {super.cause});
}

class CacheFailure extends AppFailure {
  const CacheFailure(super.message, {super.cause});
}

class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message, {super.cause});
}
