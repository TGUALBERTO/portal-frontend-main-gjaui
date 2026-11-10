import 'package:equatable/equatable.dart';

/// UMA tentativa de contagem já gravada no SAP (`INCContagemACegaLog`).
///
/// Diferente de `ContagemLancamento`: aquele é o **estado final** de uma linha
/// `(item, lote)` na sessão do coletor; este é um **evento** de um log
/// append-only. É a sequência deles que permite reconstruir `tentativas` e
/// `status` depois de o coletor cair no meio de um caminhão — ver
/// `rehidratar_nota.dart`.
class ContagemLogRegistro extends Equatable {
  const ContagemLogRegistro({
    required this.item,
    required this.contagem,
    required this.quantidade,
    this.lote = '',
    this.loteLido = '',
    this.matricula = '',
  });

  /// `Item` CHAR(5) zero-padded, **literal como o SAP devolveu**. É o que casa
  /// com `ContagemItem.itemXml`; reformatar aqui é como se perde uma linha.
  final String item;

  /// Lote da NF — junto com [item], a identidade da linha contada.
  ///
  /// Vazio quando o material não tem lote **ou** quando
  /// `ContagemCegaCampos.loteHabilitado` está desligado.
  final String lote;

  /// Ordem da tentativa, 1..n. É por este campo que o replay ordena — nunca
  /// por [ContagemLogRegistro] de data/hora, que saem do relógio do coletor e
  /// podem estar tortos.
  final int contagem;

  /// Quantidade contada nesta tentativa, na unidade do pedido — decimal, como
  /// o SAP a grava (`Edm.Decimal` de 4 casas).
  final double quantidade;

  /// Lote que o conferente leu, que pode divergir de [lote].
  final String loteLido;

  /// `Crenam` — quem contou.
  final String matricula;

  /// Chave de agrupamento da reidratação.
  (String, String) get linha => (item, lote);

  @override
  List<Object?> get props => [
        item,
        lote,
        contagem,
        quantidade,
        loteLido,
        matricula,
      ];
}
