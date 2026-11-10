import 'feature.dart';
import 'permission.dart';

/// Mutable editing model for a single row of the permission matrix
/// (one feature × four CRUD flags). Unlike [Permission] this is mutable so the
/// matrix UI can toggle flags in place before persisting.
class GroupPermissionDraft {
  final Feature feature;
  bool canCreate;
  bool canRead;
  bool canUpdate;
  bool canDelete;

  GroupPermissionDraft({
    required this.feature,
    this.canCreate = false,
    this.canRead = false,
    this.canUpdate = false,
    this.canDelete = false,
  });

  /// Builds a draft from an existing [Permission].
  factory GroupPermissionDraft.fromPermission(Permission p) =>
      GroupPermissionDraft(
        feature: p.feature,
        canCreate: p.canCreate,
        canRead: p.canRead,
        canUpdate: p.canUpdate,
        canDelete: p.canDelete,
      );

  /// Builds an empty (all-false) draft for a feature.
  factory GroupPermissionDraft.empty(Feature feature) =>
      GroupPermissionDraft(feature: feature);

  /// True when at least one CRUD flag is enabled.
  bool get hasAny => canCreate || canRead || canUpdate || canDelete;

  bool get hasAll => canCreate && canRead && canUpdate && canDelete;

  void setAll(bool value) {
    canCreate = value;
    canRead = value;
    canUpdate = value;
    canDelete = value;
  }

  void toggle(PermissionAction action) {
    switch (action) {
      case PermissionAction.create:
        canCreate = !canCreate;
      case PermissionAction.read:
        canRead = !canRead;
      case PermissionAction.update:
        canUpdate = !canUpdate;
      case PermissionAction.delete:
        canDelete = !canDelete;
    }
  }

  bool allows(PermissionAction action) => switch (action) {
        PermissionAction.create => canCreate,
        PermissionAction.read => canRead,
        PermissionAction.update => canUpdate,
        PermissionAction.delete => canDelete,
      };

  /// Serializes to the `PermissionRequest` shape expected by
  /// `PUT /groups/{id}/permissions`.
  Map<String, dynamic> toRequest() => {
        'featureId': feature.id,
        'canCreate': canCreate,
        'canRead': canRead,
        'canUpdate': canUpdate,
        'canDelete': canDelete,
      };

  GroupPermissionDraft copy() => GroupPermissionDraft(
        feature: feature,
        canCreate: canCreate,
        canRead: canRead,
        canUpdate: canUpdate,
        canDelete: canDelete,
      );
}
