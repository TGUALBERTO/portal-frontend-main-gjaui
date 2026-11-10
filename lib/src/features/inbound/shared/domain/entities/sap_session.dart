import 'package:equatable/equatable.dart';

/// Sessão SAP emitida pelo backend `core` em `GET /sap/session`.
///
/// O backend guarda o Basic do usuário de serviço (um por sistema SAP), faz o
/// `GET $metadata` com `X-CSRF-Token: Fetch` no SAP da empresa do usuário
/// autenticado e devolve o token + os cookies. O app **nunca** vê usuário/senha
/// — ele só reusa a sessão, então o segredo não vai no binário distribuído.
class SapSession extends Equatable {
  const SapSession({
    required this.sapSystem,
    required this.baseUrl,
    required this.csrfToken,
    required this.cookies,
    required this.expiresAt,
  });

  /// Sistema SAP para o qual a sessão foi emitida (`BANDEIRANTES`/`NEL`/
  /// `VITAMEDIC`). Conferido contra o backend resolvido pela empresa.
  final String sapSystem;

  /// Host contra o qual a sessão foi aberta, normalizado pelo backend. É o eco
  /// do que o app pediu: serve para o app garantir que a sessão e as chamadas de
  /// negócio caem no MESMO ambiente SAP (DEV/QAS/PRD).
  final String baseUrl;

  /// Token para o header `X-CSRF-Token` dos POSTs.
  final String csrfToken;

  /// Cookies crus do `Set-Cookie` do SAP (sessão + eventual SSO2).
  final List<String> cookies;

  final DateTime expiresAt;

  factory SapSession.fromJson(Map<String, dynamic> json) {
    final expiresIn = (json['expiresIn'] as num?)?.toInt() ?? 0;
    return SapSession(
      sapSystem: (json['sapSystem'] as String?)?.trim() ?? '',
      baseUrl: normalizeBaseUrl(json['baseUrl'] as String?),
      csrfToken: (json['csrfToken'] as String?)?.trim() ?? '',
      cookies: _cookiesFromJson(json['cookies']),
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  /// Forma canônica para comparar hosts: sem espaços, sem barra final, em
  /// minúsculas. Espelha o `SapEndpointProperties.normalizeBaseUrl` do backend —
  /// alguns hosts vêm em caixa alta (`GOISQ001.rebic.com.br`) e comparar cru
  /// daria falso negativo.
  static String normalizeBaseUrl(String? value) {
    var url = value?.trim() ?? '';
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url.toLowerCase();
  }

  static List<String> _cookiesFromJson(dynamic json) {
    if (json is List) {
      return json
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    // Tolerante a um backend que mande os cookies já concatenados.
    if (json is String && json.trim().isNotEmpty) {
      return [json.trim()];
    }
    return const [];
  }

  /// Valor pronto do header `Cookie`: só os pares `name=value`, sem os
  /// atributos (`path`, `HttpOnly`, `SameSite`…) que só valem no `Set-Cookie`.
  String get cookieHeader => cookies
      .map((c) => c.split(';').first.trim())
      .where((c) => c.isNotEmpty)
      .join('; ');

  /// Margem de 60s para não usar uma sessão que expira durante o request.
  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 60)));

  /// Sessão só é utilizável com token E cookie — o SAP valida os dois juntos.
  bool get isUsable => csrfToken.isNotEmpty && cookieHeader.isNotEmpty;

  @override
  List<Object?> get props => [sapSystem, baseUrl, csrfToken, cookies, expiresAt];
}
