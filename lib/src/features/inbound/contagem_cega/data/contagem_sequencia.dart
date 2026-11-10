import 'dart:math';

/// Marca d'água do `Contagem` de cada item contado.
///
/// `Contagem` faz parte da chave primária de `INCContagemACegaLog`
/// `(Checkin, Chave, Accesskey, nLote, Item, Contagem)`. Repetir um número já
/// gravado não é "um número feio": é chave duplicada, e o serviço responde
/// **500 `RAISE_SHORTDUMP`** (o `INSERT FROM TABLE` do ABAP dumpa em vez de
/// devolver um 409 limpo) no meio da conferência, com o conferente de pé na
/// doca.
///
/// O número sai do SAP (`max + 1` sobre o log), mas **não pode depender só
/// dele**. Entre gravar a 1ª tentativa e ler o máximo para a 2ª passam
/// milissegundos, e qualquer motivo para a linha recém-gravada não voltar nessa
/// releitura devolve máximo 0 e o app manda `1` de novo, na mesma chave. Esta
/// classe é a memória que fecha a janela: o app **nunca reusa um número que ele
/// mesmo já gravou nesta sessão**. O máximo remoto continua valendo — é ele que
/// enxerga o outro coletor na mesma nota —, mas só para **subir** o contador.
///
/// ## Escopo: `(Chave, Accesskey, Item)` — sem o lote, de propósito
///
/// O lote está na chave do log, mas **o serviço não persiste o `nLote` que o
/// app envia**: um POST com `nLote: 'C2212026'` volta na leitura com `nLote`
/// vazio. Contar por lote nesse cenário é o pior dos mundos — cada lote do
/// mesmo item começaria de novo no 1 e os dois gravariam a mesma chave
/// `(…, nLote: '', Item, Contagem: 1)`.
///
/// Vale a assimetria de risco que rege todo o incremental: escopo **mais
/// estreito** que a chave real gera número duplicado; **mais largo** só pula
/// número, o que é inofensivo (o `$filter` do SAP segue a mesma regra). Com o
/// escopo por item, dois lotes do mesmo item dividem o contador e saem com
/// números diferentes — chaves distintas, nada colide.
class ContagemSequencia {
  final Map<String, int> _ultima = <String, int>{};

  /// Próximo número para este item: o maior entre o que o SAP devolveu e o que
  /// este app já gravou, **mais um**.
  int proxima({
    required String chave,
    required String accesskey,
    required String item,
    required int maiorNoSap,
  }) {
    final k = _chave(chave, accesskey, item);
    return max(maiorNoSap, _ultima[k] ?? 0) + 1;
  }

  /// O SAP devolveu [contagem] para este item, ou o app acabou de gravá-la.
  ///
  /// Só sobe: um registro antigo chegando fora de ordem numa releitura não pode
  /// rebaixar a marca.
  void registrar({
    required String chave,
    required String accesskey,
    required String item,
    required int contagem,
  }) {
    final k = _chave(chave, accesskey, item);
    _ultima[k] = max(_ultima[k] ?? 0, contagem);
  }

  /// Maior número conhecido deste item — `0` quando nunca foi contado.
  ///
  /// Existe para o repositório conseguir avisar no log quando o SAP devolveu
  /// menos do que o app já gravou: é o sintoma de releitura que não enxerga o
  /// que foi escrito, e sem isso o problema volta a ser invisível.
  int conhecida({
    required String chave,
    required String accesskey,
    required String item,
  }) =>
      _ultima[_chave(chave, accesskey, item)] ?? 0;

  /// `\u0000` como separador: nenhum campo de chave do SAP contém o caractere, então
  /// `('AB', 'C')` e `('A', 'BC')` não podem colidir.
  String _chave(String chave, String accesskey, String item) =>
      '$chave\u0000$accesskey\u0000$item';
}
