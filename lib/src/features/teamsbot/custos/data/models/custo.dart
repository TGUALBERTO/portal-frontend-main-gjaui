import 'package:equatable/equatable.dart';

/// Uma linha agregada de custo (por fase: SANITIZACAO|GERACAO|INDEXACAO|RAG;
/// ou por provedor: ANTHROPIC|VOYAGE).
class CustoLinha extends Equatable {
  final String chave;
  final int inputTokens;
  final int outputTokens;
  final int cacheTokens;
  final double custoUsd;

  const CustoLinha({
    required this.chave,
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheTokens,
    required this.custoUsd,
  });

  int get totalTokens => inputTokens + outputTokens + cacheTokens;

  factory CustoLinha.fromJson(Map<String, dynamic> json) => CustoLinha(
        chave: json['chave']?.toString() ?? '—',
        inputTokens: (json['inputTokens'] as num?)?.toInt() ?? 0,
        outputTokens: (json['outputTokens'] as num?)?.toInt() ?? 0,
        cacheTokens: (json['cacheTokens'] as num?)?.toInt() ?? 0,
        custoUsd: (json['custoUsd'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props =>
      [chave, inputTokens, outputTokens, cacheTokens, custoUsd];
}

/// Custo agregado de uma ATA específica.
class CustoPorAta extends Equatable {
  final int ataId;
  final String assunto;
  final double custoUsd;
  final int totalTokens;

  const CustoPorAta({
    required this.ataId,
    required this.assunto,
    required this.custoUsd,
    required this.totalTokens,
  });

  factory CustoPorAta.fromJson(Map<String, dynamic> json) => CustoPorAta(
        ataId: (json['ataId'] as num).toInt(),
        assunto: json['assunto']?.toString() ?? '(sem assunto)',
        custoUsd: (json['custoUsd'] as num?)?.toDouble() ?? 0,
        totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [ataId, assunto, custoUsd, totalTokens];
}

/// Relatório de custos de IA (`GET /api/atas/custos`).
class CustoRelatorio extends Equatable {
  final double totalUsd;
  final int totalTokens;
  final List<CustoLinha> porFase;
  final List<CustoLinha> porProvedor;
  final List<CustoPorAta> porAta;

  const CustoRelatorio({
    required this.totalUsd,
    required this.totalTokens,
    required this.porFase,
    required this.porProvedor,
    required this.porAta,
  });

  factory CustoRelatorio.fromJson(Map<String, dynamic> json) {
    List<T> mapList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
      final list = (raw as List<dynamic>?) ?? const [];
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }

    return CustoRelatorio(
      totalUsd: (json['totalUsd'] as num?)?.toDouble() ?? 0,
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      porFase: mapList(json['porFase'], CustoLinha.fromJson),
      porProvedor: mapList(json['porProvedor'], CustoLinha.fromJson),
      porAta: mapList(json['porAta'], CustoPorAta.fromJson),
    );
  }

  @override
  List<Object?> get props =>
      [totalUsd, totalTokens, porFase, porProvedor, porAta];
}
