import 'package:equatable/equatable.dart';

import 'feature.dart';

enum PermissionAction { create, read, update, delete }

class Permission extends Equatable {
  final Feature feature;
  final bool canCreate;
  final bool canRead;
  final bool canUpdate;
  final bool canDelete;

  const Permission({
    required this.feature,
    this.canCreate = false,
    this.canRead = false,
    this.canUpdate = false,
    this.canDelete = false,
  });

  factory Permission.fromJson(Map<String, dynamic> json) => Permission(
        feature: Feature.fromJson(json['feature'] as Map<String, dynamic>),
        canCreate: json['canCreate'] as bool? ?? false,
        canRead: json['canRead'] as bool? ?? false,
        canUpdate: json['canUpdate'] as bool? ?? false,
        canDelete: json['canDelete'] as bool? ?? false,
      );

  bool allows(PermissionAction action) => switch (action) {
        PermissionAction.create => canCreate,
        PermissionAction.read => canRead,
        PermissionAction.update => canUpdate,
        PermissionAction.delete => canDelete,
      };

  @override
  List<Object?> get props =>
      [feature, canCreate, canRead, canUpdate, canDelete];
}
