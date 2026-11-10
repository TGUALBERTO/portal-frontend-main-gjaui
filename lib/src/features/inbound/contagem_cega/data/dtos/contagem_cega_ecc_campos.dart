import 'package:gjamobile/src/features/inbound/contagem_cega/domain/contagem_quantidade.dart';

/// Entity sets e propriedades da contagem cega no **SAP ECC**
/// (`ZGJAAUTO_GENERIC_SRV`, construído com SEGW).
///
/// Espelha `ContagemCegaCampos`, que descreve o serviço CDS do S/4HANA. Existe
/// como arquivo próprio pelo mesmo motivo do original — nome errado devolve 400
/// no POST e, pior, lista vazia no `$filter`, que a tela lê como "nunca foi
/// contado" em vez de erro — e porque os dois serviços **não usam os mesmos
/// nomes**:
///
/// | Conceito               | S/4HANA (CDS)                 | ECC (SEGW)              |
/// |------------------------|-------------------------------|-------------------------|
/// | Cabeçalho da contagem  | `INCContagemACegaHeader`      | `IN100ContagemACega`    |
/// | Log de tentativas      | `INCContagemACegaLog`         | `IN100ContagemACegaLog` |
/// | Lote                   | `nLote` (n minúsculo)         | `NLote`                 |
/// | Check-in + NF-e        | `INCheckin` + `to_Items`      | duas entidades          |
/// | Item de pedido         | `PedidoCompra` / `Material`   | `Ebeln` / `Matnr`       |
/// | Consumo XML × pedido   | `IN100XmlItemsConsumByItemPO` | `IN100XmlItmConsByItmPo`|
///
/// A CDS gerava `nLote` com inicial minúscula; o import DDIC do SEGW gera
/// `NLote`. É uma letra, e é a diferença entre o log aparecer e não aparecer.
abstract final class ContagemCegaEccCampos {
  // ── Serviço ────────────────────────────────────────────────────────────────

  /// **Um serviço só**, diferente do S/4HANA.
  ///
  /// Lá as tabelas Z da contagem vivem no `ZGJAAUTO_SB_GENERIC` (CDS) e só a
  /// finalização sai pelo `ZGJAAUTO_GENERIC_SRV`. No ECC não há serviço CDS:
  /// tudo foi reconstruído dentro do `ZGJAAUTO_GENERIC_SRV`, inclusive o
  /// cabeçalho e o log. Uma sessão só — o `SapSessionRepository` cacheia por
  /// `host|serviço`.
  static const String servico = 'sap/ZGJAAUTO_GENERIC_SRV';

  // ── Entity sets ────────────────────────────────────────────────────────────

  /// Cabeçalho do check-in do veículo (motorista, placa, status).
  ///
  /// "MOTISTA" sem o "R" é a grafia real do serviço — a mesma que a portaria
  /// usa em `InboundRepositoryImpl`.
  static const String checkinSet = 'IN100_CHECKIN_MOTISTA';

  /// NF-e vinculadas ao check-in (ZIN1008).
  ///
  /// No S/4HANA isto vinha por `$expand=to_Items` do `INCheckin`. O serviço ECC
  /// não tem a associação, então são duas leituras.
  static const String checkinItensSet = 'IN100CheckinItems';

  /// Um registro por check-in. Chave `(Checkin)`.
  static const String headerSet = 'IN100ContagemACega';

  /// Append-only, uma linha por tentativa. Chave
  /// `(Checkin, Chave, Accesskey, Item, NLote, Contagem)`.
  static const String logSet = 'IN100ContagemACegaLog';

  /// Dispara o processamento do fim da conferência. POST com só o check-in.
  static const String finalizaSet = 'IN100FinalizaCC';

  /// Fornecedor da NF-e (ZIN100VARS + LFA1).
  static const String varsSet = 'IN100Vars';

  /// Cabeçalho fiscal da NF-e (ZIN1001).
  static const String cabecalhoNfeSet = 'IN100AutomationHeader';

  /// Itens do XML da NF-e (ZIN1002).
  static const String itensNfeSet = 'IN100AutomationItems';

  /// Casamento XML × pedido (ZIN1006) — a fonte do lote e da quantidade
  /// esperada por item de pedido.
  ///
  /// **Não é o `IN1006Set`**, embora leia a mesma tabela. Aquele entity set é
  /// pré-existente e tem dois defeitos que não dá para corrigir sem quebrar
  /// quem já o consome: expõe `Mandt` como campo-chave e devolve `Menge` num
  /// componente que o Gateway não serializa como decimal — foi ele que
  /// respondeu 500 com `Property Value ''` em QAS. Este nasceu com a chave
  /// certa, os seis campos que identificam o consumo, e sem o mandante.
  static const String consumoSet = 'IN100XmlItmConsByItmPo';

  /// Itens de pedido de compras (EKKO/EKPO).
  static const String pedidosSet = 'IN100POs';

  // ── Propriedades ───────────────────────────────────────────────────────────

  static const String checkin = 'Checkin';
  static const String chave = 'Chave';
  static const String accesskey = 'Accesskey';
  static const String item = 'Item';
  static const String contagem = 'Contagem';
  static const String crenam = 'Crenam';
  static const String quantidade = 'Quantidade';
  static const String status = 'Status';

  /// `NLote` — **N maiúsculo**, ao contrário do `nLote` do serviço CDS.
  static const String lote = 'NLote';

  /// Propriedades do `IN100_CHECKIN_MOTISTA`, em CAIXA ALTA.
  ///
  /// Este entity type foi criado à mão no SEGW, sem import DDIC, e ficou com os
  /// nomes ABAP crus — diferente de todos os outros, que vieram em CamelCase.
  /// O `GET_ENTITY` dele faz `MOVE-CORRESPONDING` direto da ZIN1007.
  static const String checkinStatus = 'STATUS';
  static const String checkinMotorista = 'MOTORISTA';
  static const String checkinPlaca = 'PLACA';
  static const String checkinCpf = 'CPF';

  /// Nº do aviso de recebimento já criado para o grupo, quando existe.
  /// Informativo: a contagem não decide nada por ele.
  static const String avisoRecebimento = 'AvisoRecebimento';

  /// Propriedades do `IN100POs`, com os nomes de campo do MM.
  static const String ebeln = 'Ebeln';
  static const String ebelp = 'Ebelp';
  static const String matnr = 'Matnr';
  static const String maktx = 'Maktx';
  static const String meins = 'Meins';
  static const String menge = 'Menge';

  /// Propriedades de `IN100AutomationHeader` e `IN100AutomationItems` — iguais
  /// às do S/4HANA, porque as duas CDS também saíram das mesmas tabelas Z.
  static const String nNf = 'NNf';
  static const String serie = 'Serie';
  static const String modelo = 'Mod';
  static const String cProd = 'CProd';
  static const String xProd = 'XProd';
  static const String uCom = 'UCom';
  static const String qCom = 'QCom';

  // ── Valores de status do cabeçalho da contagem ─────────────────────────────

  /// Conferência aberta. Mesmo domínio de 1 letra do S/4HANA.
  static const String statusCabecalho = 'E';

  /// Finalizada com todas as NF-e conferidas.
  static const String statusFinalizadoConforme = 'C';

  /// Finalizada com ao menos uma NF-e para devolução.
  static const String statusFinalizadoDivergente = 'D';

  // ── Formatos ───────────────────────────────────────────────────────────────

  /// `Quantidade` é `Edm.Decimal Precision=15 Scale=4` no `$metadata` do ECC —
  /// a mesma escala do S/4HANA, e por isso a constante do domínio serve aos
  /// dois.
  static const int casasQuantidade = casasDecimaisQuantidade;
}
