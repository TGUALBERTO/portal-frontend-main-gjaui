import 'package:gjamobile/src/features/rhprocesso/domain/entities/equipe_vendas.dart';

double _num(Object? v) => (v as num?)?.toDouble() ?? 0;

DateTime? _data(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// Uma linha do detalhe de volume (item de nota), com os cálculos do legado.
class ItemVolume {
  const ItemVolume({
    required this.unidade,
    required this.numeroNota,
    required this.dataEmissao,
    required this.dataPrestacao,
    required this.rota,
    required this.codigoProduto,
    required this.descricaoProduto,
    required this.quantidade,
    required this.valorUnitario,
    required this.valorImpostoUnitario,
    required this.valorImpostoTotal,
    required this.valorUnitarioComImposto,
    required this.valorTotalComImposto,
    required this.valorTotalSemImposto,
    required this.status,
    required this.operacaoFiscal,
    required this.fatorConversao,
    required this.quantidadeCxu,
    required this.caracteristica,
  });

  factory ItemVolume.fromJson(Map<String, dynamic> json) => ItemVolume(
        unidade: json['unidade'] as String? ?? '',
        numeroNota: json['numeroNota'] as String? ?? '',
        dataEmissao: _data(json['dataEmissao']),
        dataPrestacao: _data(json['dataPrestacao']),
        rota: json['rota'] as String? ?? '',
        codigoProduto: json['codigoProduto'] as String? ?? '',
        descricaoProduto: json['descricaoProduto'] as String? ?? '',
        quantidade: _num(json['quantidade']),
        valorUnitario: _num(json['valorUnitario']),
        valorImpostoUnitario: _num(json['valorImpostoUnitario']),
        valorImpostoTotal: _num(json['valorImpostoTotal']),
        valorUnitarioComImposto: _num(json['valorUnitarioComImposto']),
        valorTotalComImposto: _num(json['valorTotalComImposto']),
        valorTotalSemImposto: _num(json['valorTotalSemImposto']),
        status: json['status'] as String? ?? '',
        operacaoFiscal: json['operacaoFiscal'] as String? ?? '',
        fatorConversao: _num(json['fatorConversao']),
        quantidadeCxu: _num(json['quantidadeCxu']),
        caracteristica: json['caracteristica'] as String? ?? '',
      );

  final String unidade;
  final String numeroNota;
  final DateTime? dataEmissao;
  final DateTime? dataPrestacao;
  final String rota;
  final String codigoProduto;
  final String descricaoProduto;
  final double quantidade;
  final double valorUnitario;

  /// ICMS-ST + IPI por unidade.
  final double valorImpostoUnitario;

  /// ICMS-ST + IPI do item.
  final double valorImpostoTotal;
  final double valorUnitarioComImposto;
  final double valorTotalComImposto;
  final double valorTotalSemImposto;
  final String status;
  final String operacaoFiscal;
  final double fatorConversao;
  final double quantidadeCxu;
  final String caracteristica;
}

/// Uma nota fiscal da consulta (cada nota uma vez).
class NotaVolume {
  const NotaVolume({
    required this.unidade,
    required this.numero,
    required this.dataEmissao,
    required this.dataPrestacao,
    required this.rota,
    required this.operacaoFiscal,
    required this.valorNota,
  });

  factory NotaVolume.fromJson(Map<String, dynamic> json) => NotaVolume(
        unidade: json['unidade'] as String? ?? '',
        numero: json['numero'] as String? ?? '',
        dataEmissao: _data(json['dataEmissao']),
        dataPrestacao: _data(json['dataPrestacao']),
        rota: json['rota'] as String? ?? '',
        operacaoFiscal: json['operacaoFiscal'] as String? ?? '',
        valorNota: _num(json['valorNota']),
      );

  final String unidade;
  final String numero;
  final DateTime? dataEmissao;
  final DateTime? dataPrestacao;
  final String rota;
  final String operacaoFiscal;
  final double valorNota;
}

/// Volume (CXU) e valor agrupados por característica de produto.
class ResumoCaracteristica {
  const ResumoCaracteristica({
    required this.caracteristica,
    required this.quantidadeCxu,
    required this.valor,
  });

  factory ResumoCaracteristica.fromJson(Map<String, dynamic> json) =>
      ResumoCaracteristica(
        caracteristica: json['caracteristica'] as String? ?? '',
        quantidadeCxu: _num(json['quantidadeCxu']),
        valor: _num(json['valor']),
      );

  final String caracteristica;
  final double quantidadeCxu;
  final double valor;
}

/// Totais da consulta, calculados pela API: os mesmos somatórios das caixas da
/// tela do desktop (Valor Total Unidade, Valor Imposto Item, ...).
class TotaisVolume {
  const TotaisVolume({
    required this.quantidadeNotas,
    required this.quantidadeItens,
    required this.quantidadeCxu,
    required this.valorComImposto,
    required this.valorSemImposto,
    required this.valorNotas,
    required this.valorUnitario,
    required this.valorImpostoUnitario,
    required this.valorImpostoTotal,
    required this.valorUnitarioComImposto,
  });

  factory TotaisVolume.fromJson(Map<String, dynamic> json) => TotaisVolume(
        quantidadeNotas: (json['quantidadeNotas'] as num?)?.toInt() ?? 0,
        quantidadeItens: (json['quantidadeItens'] as num?)?.toInt() ?? 0,
        quantidadeCxu: _num(json['quantidadeCxu']),
        valorComImposto: _num(json['valorComImposto']),
        valorSemImposto: _num(json['valorSemImposto']),
        valorNotas: _num(json['valorNotas']),
        valorUnitario: _num(json['valorUnitario']),
        valorImpostoUnitario: _num(json['valorImpostoUnitario']),
        valorImpostoTotal: _num(json['valorImpostoTotal']),
        valorUnitarioComImposto: _num(json['valorUnitarioComImposto']),
      );

  static const vazio = TotaisVolume(
    quantidadeNotas: 0,
    quantidadeItens: 0,
    quantidadeCxu: 0,
    valorComImposto: 0,
    valorSemImposto: 0,
    valorNotas: 0,
    valorUnitario: 0,
    valorImpostoUnitario: 0,
    valorImpostoTotal: 0,
    valorUnitarioComImposto: 0,
  );

  final int quantidadeNotas;

  /// Linhas do detalhe ("N registros referente a M NF-e").
  final int quantidadeItens;
  final double quantidadeCxu;
  final double valorComImposto;
  final double valorSemImposto;
  final double valorNotas;
  final double valorUnitario;
  final double valorImpostoUnitario;
  final double valorImpostoTotal;
  final double valorUnitarioComImposto;
}

/// Resposta de `GET /{consultores|supervisores}/{mat}/volume?periodo=`.
class ConsultaVolume {
  const ConsultaVolume({
    required this.equipe,
    required this.periodo,
    required this.detalhe,
    required this.notas,
    required this.resumo,
    required this.totais,
  });

  factory ConsultaVolume.fromJson(Map<String, dynamic> json) => ConsultaVolume(
        equipe: EquipeVendas.fromJson(
            json['equipe'] as Map<String, dynamic>? ?? const {}),
        periodo: json['periodo'] as String? ?? '',
        detalhe: (json['detalhe'] as List<dynamic>? ?? const [])
            .map((e) => ItemVolume.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        notas: (json['notas'] as List<dynamic>? ?? const [])
            .map((e) => NotaVolume.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        resumo: (json['resumo'] as List<dynamic>? ?? const [])
            .map((e) => ResumoCaracteristica.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        totais: json['totais'] is Map<String, dynamic>
            ? TotaisVolume.fromJson(json['totais'] as Map<String, dynamic>)
            : TotaisVolume.vazio,
      );

  final EquipeVendas equipe;
  final String periodo;
  final List<ItemVolume> detalhe;
  final List<NotaVolume> notas;
  final List<ResumoCaracteristica> resumo;
  final TotaisVolume totais;

  bool get vazia => detalhe.isEmpty && notas.isEmpty;
}
