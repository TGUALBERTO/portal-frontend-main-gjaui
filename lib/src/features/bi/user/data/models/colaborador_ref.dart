import '../../../shared/models/json_utils.dart';

/// Item do seletor de colaboradores do painel "Performance Individual". Espelha
/// o record `ColaboradorRef` do backend (`GET /dashboards/colaboradores`). O
/// [email] é usado para pré-selecionar o colaborador que está acessando.
class ColaboradorRef {
  const ColaboradorRef({
    required this.id,
    required this.nome,
    required this.squad,
    required this.empresa,
    required this.email,
  });

  final int id;
  final String nome;
  final String squad;
  final String empresa;
  final String email;

  factory ColaboradorRef.fromJson(Map<String, dynamic> j) => ColaboradorRef(
        id: parseInt(j['id']),
        nome: parseStr(j['nome']),
        squad: parseStr(j['squad']),
        empresa: parseStr(j['empresa']),
        email: parseStr(j['email']),
      );
}
