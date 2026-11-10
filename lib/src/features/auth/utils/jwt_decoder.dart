import 'dart:convert';

class JwtPayload {
  const JwtPayload(this.claims);
  final Map<String, dynamic> claims;

  String? get oid => claims['oid'] as String?;
  String? get sub => claims['sub'] as String?;
  String? get email =>
      (claims['email'] as String?) ?? (claims['preferred_username'] as String?);
  String? get name => claims['name'] as String?;
  String? get tid => claims['tid'] as String?;
}

JwtPayload decodeJwt(String jwt) {
  final parts = jwt.split('.');
  if (parts.length != 3) {
    throw const FormatException('Invalid JWT: expected 3 segments');
  }
  final normalized = base64Url.normalize(parts[1]);
  final decoded = utf8.decode(base64Url.decode(normalized));
  final json = jsonDecode(decoded) as Map<String, dynamic>;
  return JwtPayload(json);
}
