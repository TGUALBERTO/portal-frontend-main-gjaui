import 'package:equatable/equatable.dart';

import 'package:gjamobile/src/features/access/domain/enums/empresas.dart';
import 'package:gjamobile/src/features/kba/domain/entities/employee_link.dart';

/// A portal user as returned by the admin `GET /users` endpoint.
class PortalUser extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? givenName;
  final String? familyName;
  final String? preferredUsername;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  /// Vínculo de matrícula (KBA): estado, bloqueio e matrícula vinculada.
  final EmployeeLinkStatus employeeLinkStatus;
  final bool kbaBloqueado;
  final int? matricula;
  final int? codigoEmpresa;

  const PortalUser({
    required this.id,
    required this.email,
    this.name,
    this.givenName,
    this.familyName,
    this.preferredUsername,
    this.createdAt,
    this.lastLoginAt,
    this.employeeLinkStatus = EmployeeLinkStatus.unlinked,
    this.kbaBloqueado = false,
    this.matricula,
    this.codigoEmpresa,
  });

  factory PortalUser.fromJson(Map<String, dynamic> json) => PortalUser(
        id: (json['id'] ?? json['microsoftId'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        name: json['name'] as String?,
        givenName: json['givenName'] as String?,
        familyName: json['familyName'] as String?,
        preferredUsername: json['preferredUsername'] as String?,
        createdAt: DateTime.tryParse((json['createdAt'] ?? '') as String),
        lastLoginAt: DateTime.tryParse((json['lastLoginAt'] ?? '') as String),
        employeeLinkStatus:
            EmployeeLinkStatus.fromApi(json['employeeLinkStatus'] as String?),
        kbaBloqueado: (json['kbaBloqueado'] as bool?) ?? false,
        matricula: (json['matricula'] as num?)?.toInt(),
        codigoEmpresa: (json['codigoEmpresa'] as num?)?.toInt(),
      );

  PortalUser copyWith({
    EmployeeLinkStatus? employeeLinkStatus,
    bool? kbaBloqueado,
    int? matricula,
    int? codigoEmpresa,
  }) =>
      PortalUser(
        id: id,
        email: email,
        name: name,
        givenName: givenName,
        familyName: familyName,
        preferredUsername: preferredUsername,
        createdAt: createdAt,
        lastLoginAt: lastLoginAt,
        employeeLinkStatus: employeeLinkStatus ?? this.employeeLinkStatus,
        kbaBloqueado: kbaBloqueado ?? this.kbaBloqueado,
        matricula: matricula ?? this.matricula,
        codigoEmpresa: codigoEmpresa ?? this.codigoEmpresa,
      );

  bool get isLinked => employeeLinkStatus == EmployeeLinkStatus.linked;

  /// Empresa do vínculo. Nula quando o backend não mandou o código ou quando
  /// ele ainda não está mapeado em [Empresa].
  Empresa? get empresa => Empresa.fromCodigo(codigoEmpresa);

  /// Best-effort display name: full name, else username, else email.
  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final u = preferredUsername?.trim();
    if (u != null && u.isNotEmpty) return u;
    return email;
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        givenName,
        familyName,
        preferredUsername,
        createdAt,
        lastLoginAt,
        employeeLinkStatus,
        kbaBloqueado,
        matricula,
        codigoEmpresa,
      ];
}
