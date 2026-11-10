import 'package:equatable/equatable.dart';

enum KbaSubmitOutcome {
  linked,
  wrongAnswers,
  blocked;

  static KbaSubmitOutcome fromApi(String? value) => switch (value) {
        'LINKED' => KbaSubmitOutcome.linked,
        'BLOCKED' => KbaSubmitOutcome.blocked,
        _ => KbaSubmitOutcome.wrongAnswers,
      };
}

/// Desfecho do POST /kba/session/{id}/answers. O backend nunca informa quais
/// perguntas ficaram erradas.
class KbaSubmitResult extends Equatable {
  final KbaSubmitOutcome outcome;
  final int attemptsRemaining;

  const KbaSubmitResult({
    required this.outcome,
    required this.attemptsRemaining,
  });

  factory KbaSubmitResult.fromJson(Map<String, dynamic> json) {
    return KbaSubmitResult(
      outcome: KbaSubmitOutcome.fromApi(json['result'] as String?),
      attemptsRemaining: (json['attemptsRemaining'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [outcome, attemptsRemaining];
}
