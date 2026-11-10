/// Montagem de `$filter` do OData V2.
///
/// O projeto não tem query builder — o resto do app monta URL crua. Estas três
/// funções existem porque a contagem cega precisa filtrar **listas** de chaves
/// (dezenas de NF-es de um mesmo check-in), e concatenar isso à mão em quatro
/// repositórios diferentes é onde nasce injeção de aspas e URL estourada.
library;

/// Literal de string do OData V2: entre aspas simples, com a aspa interna
/// duplicada.
///
/// Sem o escape, um valor com `'` fecha o literal e o resto vira sintaxe — o
/// Gateway responde 400 e, no pior caso, o filtro passa a significar outra
/// coisa. Nenhum campo de chave do inbound tem aspa hoje, mas
/// `NomeFornecedor` (`D'ANGELO`) é texto livre e vai passar por aqui.
String odataLiteral(String value) => "'${value.replaceAll("'", "''")}'";

/// Key predicate composto: `Chave='C1',Accesskey='A1'`.
///
/// Reusa [odataLiteral] — a regra de escape da key é a mesma do `$filter`, e
/// montar isso à mão em cada repositório é onde nasce o 400.
String odataKey(Map<String, String> chaves) => chaves.entries
    .map((e) => '${e.key}=${odataLiteral(e.value)}')
    .join(',');

/// `Campo eq 'a' or Campo eq 'b'` — vazio devolve `null`.
///
/// `null` e não string vazia: um `$filter=` vazio é erro no Gateway, e o
/// chamador precisa poder omitir o parâmetro inteiro.
String? odataAnyOf(String campo, Iterable<String> valores) {
  final termos = valores.toSet().map((v) => '$campo eq ${odataLiteral(v)}');
  if (termos.isEmpty) return null;
  return termos.join(' or ');
}

/// `(A eq 'x' and B eq 'y') or (A eq 'z' and B eq 'w')` — vazio devolve `null`.
///
/// Os parênteses não são cosméticos: sem eles o `and` tem precedência sobre o
/// `or` e o filtro casa linhas erradas.
String? odataAnyOfPairs(
  String campoA,
  String campoB,
  Iterable<(String, String)> pares,
) {
  final termos = pares.toSet().map(
        (p) => '($campoA eq ${odataLiteral(p.$1)} '
            'and $campoB eq ${odataLiteral(p.$2)})',
      );
  if (termos.isEmpty) return null;
  return termos.join(' or ');
}

/// Quebra em lotes para a URL não estourar.
///
/// Um par (Chave 20 + Accesskey 44) custa ~95 caracteres codificados no
/// `$filter`; 20 pares ficam em ~1,9 KB, dentro de qualquer limite de ICM. Um
/// check-in com 60 notas num filtro só passaria de 5 KB e começaria a esbarrar
/// em limite de URI de proxy.
Iterable<List<T>> emLotes<T>(Iterable<T> itens, {int tamanho = 20}) sync* {
  if (tamanho < 1) {
    throw ArgumentError.value(tamanho, 'tamanho', 'Deve ser >= 1');
  }
  final lista = itens.toList(growable: false);
  for (var i = 0; i < lista.length; i += tamanho) {
    yield lista.sublist(i, (i + tamanho).clamp(0, lista.length));
  }
}
