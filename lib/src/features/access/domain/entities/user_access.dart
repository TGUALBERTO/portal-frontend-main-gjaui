import 'package:equatable/equatable.dart';

import 'package:gjamobile/src/features/auth/domain/entities/user.dart';
import 'package:gjamobile/src/features/kba/domain/entities/employee_link.dart';

import 'access_group.dart';

class UserAccess extends Equatable {
  final AppUser user;
  final List<AccessGroup> groups;

  /// Vínculo com a matrícula funcional (KBA). Nulo em backends antigos.
  final EmployeeLink? employeeLink;

  const UserAccess({
    required this.user,
    required this.groups,
    this.employeeLink,
  });

  factory UserAccess.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    final employeeLinkJson = json['employeeLink'];
    return UserAccess(
      user: AppUser(
        id: (userJson['id'] ?? userJson['microsoftId'] ?? '') as String,
        email: (userJson['email'] ?? '') as String,
        name: userJson['name'] as String?,
      ),
      groups: ((json['groups'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(AccessGroup.fromJson)
          .toList(growable: false),
      employeeLink: employeeLinkJson is Map<String, dynamic>
          ? EmployeeLink.fromJson(employeeLinkJson)
          : null,
    );
  }

  @override
  List<Object?> get props => [user, groups, employeeLink];
}
