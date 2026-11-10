import 'package:gjamobile/src/features/inbound/contagem_cega/domain/contagem_quantidade.dart';

/// Entity sets e nomes de propriedade das tabelas Z da contagem cega.
///
/// Existe como arquivo próprio porque errar um nome aqui custa caro: propriedade
/// inexistente no corpo de um POST devolve 400, e nome errado num `$filter`
/// devolve 400 ou lista vazia — que é pior, porque parece "nunca foi contado".
/// Concentrando aqui, o acerto é uma linha, e não uma caça a string literal
/// espalhada por DTO, repositório e filtro.
///
/// Todos os nomes abaixo saem do `$metadata` de `ZGJAAUTO_SB_GENERIC`. A única
/// pendência com o time SAP é [loteLido], que o serviço ainda não declara.
abstract final class ContagemCegaCampos {
  // ── Entity sets ────────────────────────────────────────────────────────────

  /// Um registro por **check-in**. Chave: `(Checkin)` — e só ela. O
  /// `$metadata` declara aqui apenas `Checkin`, `Credat`, `Cretim` e `Status`.
  static const String headerSet = 'INCContagemACegaHeader';

  /// Append-only: um registro por tentativa de contagem. Chave:
  /// `(Checkin, Chave, Accesskey, nLote, Item, Contagem)`.
  static const String logSet = 'INCContagemACegaLog';

  /// Entity set que **dispara o processamento** do fim da conferência no SAP.
  ///
  /// Vive no `ZGJAAUTO_GENERIC_SRV` (o serviço do check-in/check-out de
  /// veículos), **não** no `ZGJAAUTO_SB_GENERIC` das tabelas Z acima. Mesmo
  /// sistema e mesmo host — muda o path e, com ele, a sessão (o
  /// `SapSessionRepository` cacheia por `host|serviço`).
  ///
  /// Criado com SEGW: POST no entity set com o corpo `{"Checkin": "..."}`,
  /// igual ao `IN100_CHECKIN_MOTISTA` do check-in de veículos. O corpo leva
  /// **só o check-in** — o ABAP deriva o desfecho lendo o [logSet], então o
  /// `'C'`/`'D'` do MERGE não se repete aqui.
  static const String finalizaSet = 'IN100FinalizaCC';

  // ── Propriedades confirmadas ───────────────────────────────────────────────

  /// `Checkin` NUMC(10) zero-padded — qual entrada de caminhão gerou esta
  /// conferência.
  ///
  /// É a chave **inteira** do cabeçalho e o primeiro campo da chave do log.
  static const String checkin = 'Checkin';

  static const String chave = 'Chave';
  static const String accesskey = 'Accesskey';
  static const String item = 'Item';
  static const String contagem = 'Contagem';
  static const String credat = 'Credat';
  static const String cretim = 'Cretim';
  static const String crenam = 'Crenam';
  static const String quantidade = 'Quantidade';
  static const String status = 'Status';

  /// `Status` do cabeçalho na **abertura** da conferência.
  ///
  /// **Não** é `CheckinStatus.emEntrega`: os dois valem `'E'` por coincidência,
  /// em entidades diferentes. Reusar aquele enum aqui acoplaria o cabeçalho da
  /// contagem ao ciclo de vida do check-in de veículo.
  static const String statusCabecalho = 'E';

  /// `Status` do cabeçalho quando o conferente **finaliza** o check-in com
  /// todas as NF-e conferidas.
  static const String statusFinalizadoConforme = 'C';

  /// `Status` do cabeçalho quando o check-in é finalizado com **ao menos uma**
  /// NF-e condenada à devolução.
  ///
  /// Uma nota basta: o desfecho do caminhão é o pior desfecho entre as notas,
  /// porque é ele que decide o que acontece na doca. O cabeçalho é **um por
  /// check-in** (chave `(Checkin)`, sem `Chave`/`Accesskey`), então não há
  /// onde registrar desfecho por nota — isso vive no log.
  static const String statusFinalizadoDivergente = 'D';

  /// Casas decimais de [quantidade]. Confira o `Scale` no `$metadata` antes de
  /// mudar — QUAN com 3 casas pode rejeitar `'123.0000'`.
  ///
  /// `Quantidade` é `Edm.Decimal Precision=15 Scale=4`.
  ///
  /// Alias da constante do domínio: é a mesma que limita as casas no campo da
  /// tela, e o que o conferente digita tem que caber no que o SAP grava.
  static const int casasQuantidade = casasDecimaisQuantidade;

  /// Largura NUMC de [contagem] — `MaxLength="5"` no `$metadata`.
  ///
  /// Mandar `'001'` num NUMC(5) não dá 400 (cabe), mas o ABAP grava `'00001'` e
  /// a chave que voltar na leitura não é a que enviamos. Zero-padded na largura
  /// certa, o que se escreve e o que se lê são a mesma string.
  static const int larguraContagem = 5;

  // ── Lote ───────────────────────────────────────────────────────────────────

  /// Lote da NF — a **identidade** da linha contada.
  ///
  /// `nLote`, com `n` minúsculo: é assim que a propriedade sai do CDS, e
  /// `$filter` em `Lote` devolve 400 de propriedade inexistente.
  ///
  /// O mesmo `Item` do XML aparece sob vários lotes (ver
  /// `contagem_cega_mapper`), e a chave `(Checkin, Chave, Accesskey, Item)`
  /// sozinha faria as contagens dos dois lotes colidirem na releitura.
  static const String lote = 'nLote';

  /// Lote que o conferente leu/digitou — rastreabilidade.
  ///
  /// **Não existe** em [logSet]: o `$metadata` declara só `Checkin`, `Chave`,
  /// `Accesskey`, `nLote`, `Item`, `Contagem`, `Credat`, `Cretim`, `Crenam` e
  /// `Quantidade`. Enquanto o time SAP não publicar o campo, ele fica fora do
  /// POST (ver [loteLidoHabilitado]) — propriedade desconhecida no corpo é 400.
  static const String loteLido = 'LoteLido';

  /// [loteLido] existe no serviço?
  ///
  /// `false` enquanto o campo não for criado. A feature roda degradada: o lote
  /// escaneado aparece na tela durante a conferência, mas não sobrevive à
  /// reidratação depois de uma queda do coletor — o que se perde é
  /// rastreabilidade, não contagem.
  ///
  /// **Nunca** entra em `$filter`, nem quando existir: se o incremental fosse
  /// contado pelo lote digitado, um erro de digitação reiniciaria o contador e
  /// o POST tentaria reescrever uma chave existente.
  static const bool loteLidoHabilitado = false;

  /// [lote] entra no POST e na leitura. Confirmado pelo `$metadata`.
  static const bool loteHabilitado = true;

  /// **O serviço não persiste o [lote] que o app envia.** Confirmado em QAS: um
  /// POST com `nLote: 'C2212026'` volta na leitura com `nLote` vazio.
  ///
  /// Consequência para quem for mexer no incremental de [contagem]: `nLote`
  /// está na chave primária do [logSet], mas **não pode entrar no `$filter`**
  /// que calcula o próximo número — filtrar por ele devolve lista vazia mesmo
  /// com a linha gravada, e a 2ª contagem repete o número da 1ª. O serviço
  /// responde chave duplicada com **500 `RAISE_SHORTDUMP`**, não com um 409
  /// legível.
  ///
  /// O envio continua (o `$metadata` declara o campo e o time SAP vai ligar a
  /// gravação); o que não pode é alguma decisão do app *depender* de ele voltar.
  static const bool lotePersistidoPeloServico = false;
}
