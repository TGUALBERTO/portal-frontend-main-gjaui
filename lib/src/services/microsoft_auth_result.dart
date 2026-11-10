import 'dart:convert';

import '../features/auth/utils/jwt_decoder.dart';

class MicrosoftAuthResult {
  const MicrosoftAuthResult({
    required this.accessToken,
    required this.idToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
    required this.email,
    required this.name,
  });

  final String accessToken;
  final String idToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String userId;
  final String email;
  final String? name;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory MicrosoftAuthResult.fromTokens({
    required String accessToken,
    required String idToken,
    String? refreshToken,
    required DateTime expiresAt,
  }) {
    final payload = decodeJwt(idToken);
    final userId = payload.oid ?? payload.sub ?? '';
    final email = payload.email ?? '';
    return MicrosoftAuthResult(
      accessToken: accessToken,
      idToken: idToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      userId: userId,
      email: email,
      name: payload.name,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'idToken': idToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
        'userId': userId,
        'email': email,
        'name': name,
      };

  factory MicrosoftAuthResult.fromJson(Map<String, dynamic> json) {
    return MicrosoftAuthResult(
      accessToken: json['accessToken'] as String,
      idToken: json['idToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      userId: json['userId'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
    );
  }

  String encode() => jsonEncode(toJson());

  static MicrosoftAuthResult decode(String raw) =>
      MicrosoftAuthResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
