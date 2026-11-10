import 'package:equatable/equatable.dart';

import 'permission.dart';

class AccessGroup extends Equatable {
  final String id;
  final String name;
  final String? description;
  final List<Permission> permissions;

  const AccessGroup({
    required this.id,
    required this.name,
    required this.permissions,
    this.description,
  });

  factory AccessGroup.fromJson(Map<String, dynamic> json) => AccessGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        permissions: ((json['permissions'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(Permission.fromJson)
            .toList(growable: false),
      );

  @override
  List<Object?> get props => [id, name, description, permissions];
}
