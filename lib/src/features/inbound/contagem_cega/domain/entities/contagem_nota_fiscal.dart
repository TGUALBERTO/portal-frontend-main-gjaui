import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_item.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/nota_chave.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_item_status.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_nf_status.dart';

/// Uma NF-e do check-in, com os itens a conferir.
///
/// O status não é um campo: é derivado dos itens, para que gravar uma contagem
/// não possa deixar nota e itens em desacordo.
class ContagemNotaFiscal extends Equatable {
  const ContagemNotaFiscal({
    required this.chave,
    required this.chaveAcesso,
    required this.numero,
    required this.fornecedor,
    required this.itens,
    this.serie = '',
    this.modelo = '',
    this.fornecedorCodigo = '',
  });

  /// `Chave` da automação, CHAR(20).
  ///
  /// Não aparece na tela, mas é **metade da chave primária** de todos os entity
  /// sets de item — sem ela a nota não consegue nem se identificar para buscar
  /// os próprios itens.
  final String chave;

  /// `Accesskey` — chave de acesso de 44 dígitos.
  final String chaveAcesso;

  /// Número da NF-e como o fornecedor imprime ("021.383").
  final String numero;

  /// Razão social do emitente.
  final String fornecedor;

  /// Código do fornecedor no SAP (`Lifnr`). Serve de fallback de exibição
  /// enquanto o nome não vier.
  final String fornecedorCodigo;

  final String serie;
  final String modelo;

  final List<ContagemItem> itens;

  /// Par que identifica a nota nos entity sets de item.
  NotaChave get id => NotaChave(chave: chave, accesskey: chaveAcesso);

  /// Nome do fornecedor, ou o código quando o nome não veio.
  String get fornecedorLabel =>
      fornecedor.isNotEmpty ? fornecedor : (fornecedorCodigo.isNotEmpty ? fornecedorCodigo : '—');

  /// Regra do processo: **uma** divergência confirmada devolve a nota inteira,
  /// não só o item — por isso a divergência ganha da conferência dos demais.
  ContagemNfStatus get status {
    if (itens.any((i) => i.status == ContagemItemStatus.divergente)) {
      return ContagemNfStatus.devolver;
    }
    if (itens.isNotEmpty &&
        itens.every((i) => i.status == ContagemItemStatus.ok)) {
      return ContagemNfStatus.ok;
    }
    return ContagemNfStatus.pendente;
  }

  int get totalItens => itens.length;

  int get itensConferidos =>
      itens.where((i) => i.status != ContagemItemStatus.pendente).length;

  /// 0..1 — alimenta a barra de progresso do card da nota.
  double get progresso => totalItens == 0 ? 0 : itensConferidos / totalItens;

  /// "2/4"
  String get progressoLabel => '$itensConferidos/$totalItens';

  /// Chave encurtada — 44 dígitos não cabem na tela do coletor, e o conferente
  /// só precisa do começo e do fim para bater com o DANFE.
  String get chaveResumida {
    if (chaveAcesso.length <= 16) return chaveAcesso;
    final inicio = chaveAcesso.substring(0, 6);
    final fim = chaveAcesso.substring(chaveAcesso.length - 10);
    return '$inicio … $fim';
  }

  /// Índice do próximo item a contar, ou `-1` se não houver.
  int get primeiroItemPendente =>
      itens.indexWhere((i) => i.status == ContagemItemStatus.pendente);

  List<ContagemItem> get itensDivergentes =>
      itens.where((i) => i.status == ContagemItemStatus.divergente).toList();

  ContagemNotaFiscal copyWith({List<ContagemItem>? itens}) {
    return ContagemNotaFiscal(
      chave: chave,
      chaveAcesso: chaveAcesso,
      numero: numero,
      fornecedor: fornecedor,
      fornecedorCodigo: fornecedorCodigo,
      serie: serie,
      modelo: modelo,
      itens: itens ?? this.itens,
    );
  }

  @override
  List<Object?> get props => [
        chave,
        chaveAcesso,
        numero,
        fornecedor,
        fornecedorCodigo,
        serie,
        modelo,
        itens,
      ];
}
