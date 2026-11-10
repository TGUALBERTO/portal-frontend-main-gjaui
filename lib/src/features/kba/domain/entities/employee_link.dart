import 'package:equatable/equatable.dart';

import 'package:gjamobile/src/features/access/domain/enums/empresas.dart';

/// Estado do vínculo usuário x matrícula no portal.
enum EmployeeLinkStatus {
  unlinked,
  linked;

  static EmployeeLinkStatus fromApi(String? value) =>
      value?.toUpperCase() == 'LINKED'
          ? EmployeeLinkStatus.linked
          : EmployeeLinkStatus.unlinked;
}

/// Situação do vínculo com a matrícula funcional, embutida no GET /users/me
/// (campo `employeeLink`). Ausente em backends antigos — tratar como nulo.
class EmployeeLink extends Equatable {
  final EmployeeLinkStatus status;
  final bool bloqueado;
  final bool kbaAvailable;
  final int attemptsRemaining;
  final int? matricula;
  final int? codigoEmpresa;
  final String? cpfMasked;

  const EmployeeLink({
    required this.status,
    required this.bloqueado,
    required this.kbaAvailable,
    required this.attemptsRemaining,
    this.matricula,
    this.codigoEmpresa,
    this.cpfMasked,
  });

  factory EmployeeLink.fromJson(Map<String, dynamic> json) {
    return EmployeeLink(
      status: EmployeeLinkStatus.fromApi(json['status'] as String?),
      bloqueado: (json['bloqueado'] as bool?) ?? false,
      kbaAvailable: (json['kbaAvailable'] as bool?) ?? false,
      attemptsRemaining: (json['attemptsRemaining'] as num?)?.toInt() ?? 0,
      matricula: (json['matricula'] as num?)?.toInt(),
      codigoEmpresa: (json['codigoEmpresa'] as num?)?.toInt(),
      cpfMasked: json['cpfMasked'] as String?,
    );
  }

  bool get isLinked => status == EmployeeLinkStatus.linked;

  /// Empresa do vínculo. Nula quando o backend não mandou o código ou quando
  /// ele ainda não está mapeado em [Empresa].
  Empresa? get empresa => Empresa.fromCodigo(codigoEmpresa);

  /// O usuário precisa passar pelo fluxo de vínculo (inclui o estado
  /// bloqueado — a tela do fluxo renderiza o aviso de bloqueio).
  bool get needsLink => kbaAvailable && !isLinked;

  @override
  List<Object?> get props => [
        status,
        bloqueado,
        kbaAvailable,
        attemptsRemaining,
        matricula,
        codigoEmpresa,
        cpfMasked,
      ];
}
