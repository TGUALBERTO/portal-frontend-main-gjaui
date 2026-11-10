import 'package:equatable/equatable.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_item_status.dart';

/// O resultado da conferência de UMA linha `(item, lote)`, pronto para gravação.
///
/// Existe antes de haver onde gravar. Hoje nenhum entity set do
/// `ZGJAAUTO_SB_GENERIC` tem granularidade `(Chave, Accesskey, Item, nLote)` com
/// campos de contagem — a conferência vive só na memória do coletor, e uma queda
/// no meio perde tudo.
///
/// Quando as tabelas Z existirem, a chave desta classe é exatamente a chave
/// delas, e a gravação vira um método a mais no repositório: nada de controller,
/// entity ou tela precisa mudar.
class ContagemLancamento extends Equatable {
  const ContagemLancamento({
    required this.checkin,
    required this.chave,
    required this.accesskey,
    required this.item,
    required this.lote,
    required this.quantidadeContada,
    required this.loteLido,
    required this.tentativas,
    required this.status,
  });

  /// NUMC(10) zero-padded.
  final String checkin;

  /// `Chave` da automação, CHAR(20).
  final String chave;

  /// `Accesskey` da NF-e, 44 dígitos.
  final String accesskey;

  /// `Item` CHAR(5) zero-padded.
  final String item;

  /// `nLote` — vazio quando o material não tem lote.
  final String lote;

  /// `null` enquanto o item não foi contado.
  final double? quantidadeContada;

  /// Lote lido pelo conferente, que pode divergir do lote da nota.
  final String loteLido;

  final int tentativas;
  final ContagemItemStatus status;

  /// Linha ainda não conferida — não tem o que gravar.
  bool get vazio => quantidadeContada == null && tentativas == 0;

  @override
  List<Object?> get props => [
        checkin,
        chave,
        accesskey,
        item,
        lote,
        quantidadeContada,
        loteLido,
        tentativas,
        status,
      ];
}
