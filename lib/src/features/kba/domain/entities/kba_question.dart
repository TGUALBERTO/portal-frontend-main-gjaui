import 'package:equatable/equatable.dart';

/// Pergunta de múltipla escolha do KBA. O gabarito nunca chega ao cliente —
/// a validação é exclusivamente server-side.
class KbaQuestion extends Equatable {
  final String id;
  final String prompt;
  final List<String> options;

  const KbaQuestion({
    required this.id,
    required this.prompt,
    required this.options,
  });

  factory KbaQuestion.fromJson(Map<String, dynamic> json) {
    return KbaQuestion(
      id: json['id'] as String,
      prompt: json['prompt'] as String,
      options: ((json['options'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [id, prompt, options];
}
