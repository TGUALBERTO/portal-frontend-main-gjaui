import 'package:equatable/equatable.dart';

import 'kba_question.dart';

/// Sessão de perguntas devolvida pelo POST /kba/session.
class KbaSession extends Equatable {
  final String sessionId;
  final int attemptNumber;
  final int attemptsRemaining;
  final DateTime? expiresAt;
  final List<KbaQuestion> questions;

  const KbaSession({
    required this.sessionId,
    required this.attemptNumber,
    required this.attemptsRemaining,
    required this.questions,
    this.expiresAt,
  });

  factory KbaSession.fromJson(Map<String, dynamic> json) {
    return KbaSession(
      sessionId: json['sessionId'] as String,
      attemptNumber: (json['attemptNumber'] as num?)?.toInt() ?? 1,
      attemptsRemaining: (json['attemptsRemaining'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      questions: ((json['questions'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(KbaQuestion.fromJson)
          .toList(growable: false),
    );
  }

  /// Última tentativa disponível — a UI exibe o aviso de "última chance".
  bool get isLastAttempt => attemptsRemaining <= 1;

  @override
  List<Object?> get props =>
      [sessionId, attemptNumber, attemptsRemaining, expiresAt, questions];
}
