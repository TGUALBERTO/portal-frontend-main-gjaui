import 'package:gjamobile/src/extensions/date_time_extension.dart';

/// Filtros opcionais da consulta RAG. Datas como `"yyyy-MM-dd"`.
class ConsultaFiltros {
  final String? empresa;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String? participante;

  const ConsultaFiltros({
    this.empresa,
    this.dataInicio,
    this.dataFim,
    this.participante,
  });

  bool get isEmpty =>
      (empresa?.isEmpty ?? true) &&
      dataInicio == null &&
      dataFim == null &&
      (participante?.isEmpty ?? true);

  Map<String, dynamic> toJson() => {
        if (empresa != null && empresa!.isNotEmpty) 'empresa': empresa,
        if (dataInicio != null) 'dataInicio': dataInicio!.toIso8601DateOnly,
        if (dataFim != null) 'dataFim': dataFim!.toIso8601DateOnly,
        if (participante != null && participante!.isNotEmpty)
          'participante': participante,
      };
}

/// Corpo de `POST /api/atas/consultar`.
class ConsultaRequest {
  final String pergunta;
  final ConsultaFiltros? filtros;
  final String? usuarioId;

  const ConsultaRequest({
    required this.pergunta,
    this.filtros,
    this.usuarioId,
  });

  Map<String, dynamic> toJson() => {
        'pergunta': pergunta,
        if (filtros != null && !filtros!.isEmpty) 'filtros': filtros!.toJson(),
        if (usuarioId != null && usuarioId!.isNotEmpty) 'usuarioId': usuarioId,
      };
}
