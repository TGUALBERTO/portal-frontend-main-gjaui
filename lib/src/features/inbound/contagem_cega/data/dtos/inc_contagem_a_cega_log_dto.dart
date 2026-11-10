import 'package:gjamobile/src/features/inbound/contagem_cega/data/dtos/inc_contagem_a_cega_campos.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_log_registro.dart';
import 'package:gjamobile/src/features/inbound/shared/data/odata_json.dart';
import 'package:gjamobile/src/features/inbound/shared/data/odata_write.dart';


/// `INCContagemACegaLog` — append-only, uma linha por tentativa de contagem.
class IncContagemACegaLogDto {
  const IncContagemACegaLogDto({
    required this.chave,
    required this.accesskey,
    required this.item,
    required this.lote,
    required this.loteLido,
    required this.contagem,
    required this.quantidade,
    required this.crenam,
  });

  /// `Chave` + `Accesskey` — de qual NF-e é esta tentativa.
  ///
  /// Não servem para nada quando se lê uma nota por vez (o chamador já sabe),
  /// mas são o que permite ler o log do **caminhão inteiro** numa ida só e
  /// devolver cada linha à sua nota.
  final String chave;
  final String accesskey;

  /// CHAR(5) como o SAP devolveu — nunca reformatado.
  final String item;

  final String lote;
  final String loteLido;

  /// `Contagem` chega como NUMC (`'001'`) e vira `int` para poder ordenar e
  /// incrementar. `'002'.compareTo('010')` funcionaria, mas `'10'` vs `'9'` não
  /// — e não há garantia de largura se o domínio mudar.
  final int contagem;

  /// `Edm.Decimal` chega como **string** (`'123.0000'`).
  final double? quantidade;

  final String crenam;

  factory IncContagemACegaLogDto.fromJson(Map<String, dynamic> json) =>
      IncContagemACegaLogDto(
        chave: odataString(json[ContagemCegaCampos.chave]),
        accesskey: odataString(json[ContagemCegaCampos.accesskey]),
        item: odataString(json[ContagemCegaCampos.item]),
        lote: odataString(json[ContagemCegaCampos.lote]),
        loteLido: odataString(json[ContagemCegaCampos.loteLido]),
        contagem:
            int.tryParse(odataString(json[ContagemCegaCampos.contagem])) ?? 0,
        quantidade: odataDecimal(json[ContagemCegaCampos.quantidade]),
        crenam: odataString(json[ContagemCegaCampos.crenam]),
      );

  /// Par que identifica a NF-e desta tentativa.
  (String, String) get nota => (chave, accesskey);

  /// Entidade de domínio. A quantidade segue **decimal**, como o SAP gravou —
  /// arredondar aqui faria a reidratação divergir da contagem que o
  /// conferente fez (2,5 KG gravado voltaria como 3 e "não bateria").
  ContagemLogRegistro toRegistro() => ContagemLogRegistro(
        item: item,
        lote: lote,
        loteLido: loteLido,
        contagem: contagem,
        quantidade: quantidade ?? 0,
        matricula: crenam,
      );

  /// Corpo do POST de uma tentativa.
  ///
  /// Cada campo de lote entra sob o seu próprio kill switch: `nLote` existe no
  /// serviço, `LoteLido` ainda não — e mandar propriedade que o serviço não
  /// declara devolve 400.
  static Map<String, dynamic> corpoRegistro({
    required String checkin,
    required String chave,
    required String accesskey,
    required String item,
    required String lote,
    required String loteLido,
    required int contagem,
    required double quantidade,
    required String matricula,
    required DateTime momento,
  }) =>
      {
        ContagemCegaCampos.checkin: checkin,
        ContagemCegaCampos.chave: chave,
        ContagemCegaCampos.accesskey: accesskey,
        ContagemCegaCampos.item: item,
        ContagemCegaCampos.contagem:
            odataNumc(contagem, ContagemCegaCampos.larguraContagem),
        ContagemCegaCampos.credat: odataDate(momento),
        ContagemCegaCampos.cretim: odataTime(momento),
        ContagemCegaCampos.crenam: matricula,
        ContagemCegaCampos.quantidade: odataDecimalString(
          quantidade,
          casas: ContagemCegaCampos.casasQuantidade,
        ),
        if (ContagemCegaCampos.loteHabilitado) ContagemCegaCampos.lote: lote,
        if (ContagemCegaCampos.loteLidoHabilitado)
          ContagemCegaCampos.loteLido: loteLido,
      };
}
