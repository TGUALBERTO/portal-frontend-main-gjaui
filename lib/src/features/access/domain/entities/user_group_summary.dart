import 'package:equatable/equatable.dart';

/// A member of a group as returned by `GET /groups/{id}/users`.
class UserGroupSummary extends Equatable {
  final String userId;
  final String email;
  final String? name;

  const UserGroupSummary({
    required this.userId,
    required this.email,
    this.name,
  });

  factory UserGroupSummary.fromJson(Map<String, dynamic> json) =>
      UserGroupSummary(
        userId: (json['userId'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        name: json['name'] as String?,
      );

  /// Display name: name when present, else email.
  String get displayName {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    return email;
  }

  @override
  List<Object?> get props => [userId, email, name];
}
