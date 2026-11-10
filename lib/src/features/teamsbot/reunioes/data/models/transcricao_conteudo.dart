import 'package:equatable/equatable.dart';

/// Conteúdo da transcrição de uma reunião, em falas — para exibir como chat.
class TranscricaoConteudo extends Equatable {
  final int reuniaoId;
  final bool disponivel;
  final List<TranscricaoFala> falas;
  final String? texto;
  final bool sanitizadaDisponivel;
  final String? textoSanitizado;

  const TranscricaoConteudo({
    required this.reuniaoId,
    required this.disponivel,
    required this.falas,
    this.texto,
    this.sanitizadaDisponivel = false,
    this.textoSanitizado,
  });

  factory TranscricaoConteudo.fromJson(Map<String, dynamic> json) =>
      TranscricaoConteudo(
        reuniaoId: (json['reuniaoId'] as num?)?.toInt() ?? 0,
        disponivel: json['disponivel'] == true,
        falas: ((json['falas'] as List<dynamic>?) ?? const [])
            .map((e) => TranscricaoFala.fromJson(e as Map<String, dynamic>))
            .toList(),
        texto: json['texto']?.toString(),
        sanitizadaDisponivel: json['sanitizadaDisponivel'] == true,
        textoSanitizado: json['textoSanitizado']?.toString(),
      );

  @override
  List<Object?> get props =>
      [reuniaoId, disponivel, falas, texto, sanitizadaDisponivel, textoSanitizado];
}

/// Uma fala da transcrição (falante + texto + janela de tempo).
class TranscricaoFala extends Equatable {
  final String? falante;
  final String texto;
  final int inicioMs;
  final int fimMs;

  const TranscricaoFala({
    this.falante,
    required this.texto,
    required this.inicioMs,
    required this.fimMs,
  });

  factory TranscricaoFala.fromJson(Map<String, dynamic> json) => TranscricaoFala(
        falante: json['falante']?.toString(),
        texto: json['texto']?.toString() ?? '',
        inicioMs: (json['inicioMs'] as num?)?.toInt() ?? 0,
        fimMs: (json['fimMs'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [falante, texto, inicioMs, fimMs];
}
