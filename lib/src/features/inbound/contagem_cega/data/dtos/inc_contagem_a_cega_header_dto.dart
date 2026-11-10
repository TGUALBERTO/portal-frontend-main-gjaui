import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/inc_contagem_a_cega_campos.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_header_status.dart';
import 'package:gjamobile/src/features/inbound/shared/data/odata_json.dart';
import 'package:gjamobile/src/features/inbound/shared/data/odata_write.dart';

/// `INCContagemACegaHeader` — um registro por **check-in**.
///
/// Chave `(Checkin)`, e só ela: o `$metadata` do `ZGJAAUTO_SB_GENERIC` declara
/// esta entidade com `Checkin`, `Credat`, `Cretim` e `Status` — `Chave` e
/// `Accesskey` **não existem aqui**, elas só aparecem no log. Ou seja: o
/// cabeçalho abre a conferência do caminhão inteiro, não de cada NF-e.
class IncContagemACegaHeaderDto {
  const IncContagemACegaHeaderDto({
    required this.checkin,
    required this.status,
  });

  /// NUMC(10) como o SAP devolveu — nunca reformatado.
  final String checkin;

  final String status;

  factory IncContagemACegaHeaderDto.fromJson(Map<String, dynamic> json) =>
      IncContagemACegaHeaderDto(
        checkin: odataString(json[ContagemCegaCampos.checkin]),
        status: odataString(json[ContagemCegaCampos.status]),
      );

  /// A entidade existe de fato.
  ///
  /// Não basta o GET ter respondido 200: há configuração de Gateway que devolve
  /// a entidade em branco em vez de 404, e ler isso como "existe" faria o POST
  /// nunca acontecer — deixando todo o log órfão.
  bool get existe => checkin.isNotEmpty;

  /// [status] traduzido para o domínio.
  ///
  /// Cabeçalho ausente vira [ContagemHeaderStatus.inexistente] e não
  /// [ContagemHeaderStatus.desconhecido]: quem lê pela key trata 404 como
  /// "nunca teve contagem", e um status vindo de uma entidade em branco é a
  /// mesma coisa.
  ContagemHeaderStatus get statusContagem {
    if (!existe) return ContagemHeaderStatus.inexistente;
    return switch (status.trim().toUpperCase()) {
      ContagemCegaCampos.statusCabecalho => ContagemHeaderStatus.aberto,
      ContagemCegaCampos.statusFinalizadoConforme =>
        ContagemHeaderStatus.finalizadoConforme,
      ContagemCegaCampos.statusFinalizadoDivergente =>
        ContagemHeaderStatus.finalizadoDivergente,
      _ => ContagemHeaderStatus.desconhecido,
    };
  }

  /// Corpo do POST de criação.
  ///
  /// Só os quatro campos declarados no `$metadata`: mandar propriedade que a
  /// entidade não tem devolve 400.
  ///
  /// `Credat`/`Cretim` saem do [momento] **local** do coletor (ver
  /// `odata_write.dart`). Se o serviço preencher esses campos sozinho no create,
  /// os valores são cosméticos e não atrapalham.
  static Map<String, dynamic> corpoCriacao({
    required String checkin,
    required DateTime momento,
  }) =>
      {
        ContagemCegaCampos.checkin: checkin,
        ContagemCegaCampos.credat: odataDate(momento),
        ContagemCegaCampos.cretim: odataTime(momento),
        ContagemCegaCampos.status: ContagemCegaCampos.statusCabecalho,
      };

  /// Corpo do MERGE que **fecha** a conferência do check-in.
  ///
  /// Só o `Status`: MERGE é atualização parcial, então o que não vai no corpo
  /// fica como está — e reenviar `Credat`/`Cretim` aqui sobrescreveria a hora
  /// de **abertura** da conferência com a de fechamento.
  ///
  /// A chave não entra no corpo: ela vai na URL da entidade
  /// (`INCContagemACegaHeader('0000000031')`).
  static Map<String, dynamic> corpoFinalizacao({required String status}) =>
      {ContagemCegaCampos.status: status};
}
