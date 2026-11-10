import 'package:equatable/equatable.dart';

/// Participante monitorado de uma reunião.
class Participante extends Equatable {
  final String userId;
  final String? nome; // displayName do membro no Entra ID (pode vir nulo)
  final String? papel; // ORGANIZADOR | CONVIDADO
  final String?
      resposta; // ACEITO | TENTATIVO | RECUSADO | NAO_RESPONDIDO | ORGANIZADOR

  const Participante(
      {required this.userId, this.nome, this.papel, this.resposta});

  factory Participante.fromJson(Map<String, dynamic> json) => Participante(
        userId: json['userId']?.toString() ?? '',
        nome: json['nome']?.toString(),
        papel: json['papel']?.toString(),
        resposta: json['resposta']?.toString(),
      );

  /// Rótulo de exibição: nome quando disponível, senão o id (fallback).
  String get displayName => (nome != null && nome!.isNotEmpty) ? nome! : userId;

  @override
  List<Object?> get props => [userId, nome, papel, resposta];
}
