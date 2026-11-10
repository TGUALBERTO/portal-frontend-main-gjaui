import 'package:gjamobile/src/features/inbound/contagem_cega/domain/contagem_quantidade.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/contagem_regras.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_item.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_log_registro.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/entities/contagem_nota_fiscal.dart';
import 'package:gjamobile/src/features/inbound/contagem_cega/domain/enums/contagem_item_status.dart';
import 'package:gjamobile/src/utils/utils.dart';

/// [rehidratarNota] aplicado ao caminhão inteiro.
///
/// Existe separado porque a ordem de carga é a mais perigosa da feature: as
/// notas chegam do mapper todas `Pendente`, e é só o log que sabe que uma delas
/// já foi marcada para **devolução**. Entregar um registro à nota errada aqui
/// não dá erro nenhum — só troca o status de duas notas na lista.
///
/// [registrosPorNota] é chaveado por `(Chave, Accesskey)`. Nota sem registro
/// volta intacta.
List<ContagemNotaFiscal> rehidratarNotas({
  required List<ContagemNotaFiscal> notas,
  required Map<(String, String), List<ContagemLogRegistro>> registrosPorNota,
  int maxTentativas = maxTentativasContagem,
}) {
  if (registrosPorNota.isEmpty) return notas;
  return notas
      .map((nota) => rehidratarNota(
            nota: nota,
            registros: registrosPorNota[(nota.chave, nota.chaveAcesso)] ??
                const [],
            maxTentativas: maxTentativas,
          ))
      .toList(growable: false);
}

/// Reconstrói o estado da conferência de uma nota a partir do log do SAP.
///
/// É o que faz a contagem sobreviver a uma queda do coletor: ao reabrir a NF-e,
/// os itens voltam com o status e o número de tentativa que já tinham.
///
/// Função **pura** e no domínio (não em `data/mappers/`): `mapearNotas` traduz
/// DTO → domínio, isto **reexecuta a regra de negócio** das tentativas. Se
/// morasse na data layer, a regra existiria em duas camadas e sairia de
/// sincronia na primeira mudança.
///
/// Não trata casos especiais: faz **replay** das tentativas na ordem em que
/// foram gravadas, aplicando exatamente a mesma regra de
/// `ContagemCegaController.confirmarContagem`. Qualquer sequência — inclusive
/// uma que a tela não produziria — resolve como resolveria se tivesse sido
/// digitada agora.
ContagemNotaFiscal rehidratarNota({
  required ContagemNotaFiscal nota,
  required List<ContagemLogRegistro> registros,
  int maxTentativas = maxTentativasContagem,
}) {
  if (registros.isEmpty) return nota;

  final porLinha = <(String, String), List<ContagemLogRegistro>>{};
  for (final registro in registros) {
    (porLinha[registro.linha] ??= []).add(registro);
  }
  // O OData V2 não garante ordem sem `$orderby`, e a ordem é o que define o
  // replay. Ordenar por `contagem` — nunca por data/hora, que saem do relógio
  // do coletor.
  for (final grupo in porLinha.values) {
    grupo.sort((a, b) => a.contagem.compareTo(b.contagem));
  }

  // Quantas linhas da nota cada item tem. Um item com uma linha só não tem
  // ambiguidade de lote — e é o que permite recuperar o registro que voltou do
  // SAP sem lote (ver [_linhaDoRegistro]).
  final linhasPorItem = <String, int>{};
  for (final item in nota.itens) {
    linhasPorItem[item.itemXml] = (linhasPorItem[item.itemXml] ?? 0) + 1;
  }

  final usadas = <(String, String)>{};
  final itens = nota.itens.map((item) {
    final linha = (item.itemXml, item.loteNf);
    final grupo = <ContagemLogRegistro>[];

    final exato = porLinha[linha];
    if (exato != null) {
      grupo.addAll(exato);
      usadas.add(linha);
    }

    // O serviço não persiste o `nLote` enviado: a contagem gravada com lote
    // volta na leitura com lote vazio. Descartá-la faria a tela dizer "nunca
    // contado" sobre uma contagem que existe — e o conferente contaria de novo.
    //
    // Só vale quando o item tem UMA linha na nota: com dois lotes não dá para
    // saber de qual deles foi o registro, e chutar inflaria a tentativa do lote
    // errado — que é o que decide devolução de carga.
    if (item.loteNf.isNotEmpty && linhasPorItem[item.itemXml] == 1) {
      final semLote = porLinha[(item.itemXml, '')];
      if (semLote != null) {
        grupo.addAll(semLote);
        usadas.add((item.itemXml, ''));
      }
    }

    if (grupo.isEmpty) return item;
    grupo.sort((a, b) => a.contagem.compareTo(b.contagem));
    return _replay(item: item, grupo: grupo, maxTentativas: maxTentativas);
  }).toList(growable: false);

  // Registros para uma linha que a nota não tem. Nunca criar item fantasma: a
  // lista vem do XML, que é a verdade do que está fisicamente na doca. Um órfão
  // significa que o layout de lote mudou no SAP ou que o nome do campo de lote
  // está errado — e as duas coisas precisam aparecer no log, não na tela.
  for (final linha in porLinha.keys) {
    if (usadas.contains(linha)) continue;
    AppLogger.warning(
      'Contagem cega: NF-e ${nota.numero} tem contagem gravada para o item '
      '"${linha.$1}" lote "${linha.$2}", que não existe nesta nota. '
      'Registro ignorado.',
    );
  }

  return nota.copyWith(itens: itens);
}

/// Aplica as tentativas de uma linha, na ordem, sobre o item.
ContagemItem _replay({
  required ContagemItem item,
  required List<ContagemLogRegistro> grupo,
  required int maxTentativas,
}) {
  var tentativas = 0;
  var status = ContagemItemStatus.pendente;
  double? quantidade;
  var loteLido = item.loteLido;

  for (final registro in grupo) {
    quantidade = registro.quantidade;
    if (registro.loteLido.isNotEmpty) loteLido = registro.loteLido;

    // Com tolerância, nunca `==`: a esperada é soma de decimais e a contada
    // volta do SAP por string — mesma comparação de `confirmarContagem`.
    if (quantidadesConferem(registro.quantidade, item.quantidadeNf)) {
      // Contagem que bate NÃO consome tentativa — mesma regra de
      // `confirmarContagem`.
      status = ContagemItemStatus.ok;
      continue;
    }

    tentativas++;
    status = tentativas >= maxTentativas
        ? ContagemItemStatus.divergente
        : ContagemItemStatus.pendente;
  }

  return item.copyWith(
    status: status,
    tentativas: tentativas,
    quantidadeContada: quantidade,
    loteLido: loteLido,
  );
}
