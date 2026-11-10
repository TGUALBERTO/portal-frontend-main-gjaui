import 'package:equatable/equatable.dart';

/// Perfil do usuário logado retornado pelo Microsoft Graph (`GET /me`).
/// Todos os campos são opcionais — o Graph só devolve o que o tenant expõe.
class GraphProfile extends Equatable {
  const GraphProfile({
    this.displayName,
    this.givenName,
    this.surname,
    this.mail,
    this.userPrincipalName,
    this.jobTitle,
    this.department,
    this.officeLocation,
    this.mobilePhone,
    this.businessPhones = const [],
    this.preferredLanguage,
  });

  final String? displayName;
  final String? givenName;
  final String? surname;
  final String? mail;
  final String? userPrincipalName;
  final String? jobTitle;
  final String? department;
  final String? officeLocation;
  final String? mobilePhone;
  final List<String> businessPhones;
  final String? preferredLanguage;

  /// E-mail efetivo: `mail` quando presente, senão o UPN.
  String? get email => mail ?? userPrincipalName;

  /// Primeiro telefone disponível (móvel ou comercial).
  String? get phone {
    final m = mobilePhone?.trim();
    if (m != null && m.isNotEmpty) return m;
    return businessPhones.isNotEmpty ? businessPhones.first : null;
  }

  factory GraphProfile.fromJson(Map<String, dynamic> json) => GraphProfile(
        displayName: json['displayName'] as String?,
        givenName: json['givenName'] as String?,
        surname: json['surname'] as String?,
        mail: json['mail'] as String?,
        userPrincipalName: json['userPrincipalName'] as String?,
        jobTitle: json['jobTitle'] as String?,
        department: json['department'] as String?,
        officeLocation: json['officeLocation'] as String?,
        mobilePhone: json['mobilePhone'] as String?,
        businessPhones: ((json['businessPhones'] as List?) ?? const [])
            .whereType<String>()
            .toList(growable: false),
        preferredLanguage: json['preferredLanguage'] as String?,
      );

  @override
  List<Object?> get props => [
        displayName,
        givenName,
        surname,
        mail,
        userPrincipalName,
        jobTitle,
        department,
        officeLocation,
        mobilePhone,
        businessPhones,
        preferredLanguage,
      ];
}
