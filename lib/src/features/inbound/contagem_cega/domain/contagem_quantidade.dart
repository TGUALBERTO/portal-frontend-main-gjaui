/// Quantidade contada: parse, formato e comparação.
///
/// A contagem é **decimal**, na unidade de medida do pedido de compra. Material
/// comprado em KG, L ou M chega com fração na NF-e e é contado com fração —
/// arredondar para inteiro (como se fazia) fazia 2,5 KG virar 3 e a divergência
/// aparecer na doca sem explicação.
///
/// Mora no domínio porque as três camadas precisam do **mesmo** critério: a
/// tela limita as casas ao digitar, o controller compara o que foi contado com
/// o que a NF declarou, e a reidratação reexecuta essa comparação sobre o log
/// do SAP. Duas cópias sairiam de sincronia na primeira mudança.
library;

/// Casas decimais da quantidade.
///
/// É o `Scale` do `Edm.Decimal` de `Quantidade` no `INCContagemACegaLog`
/// (`Precision=15 Scale=4`): o campo da tela não deixa digitar mais casas do
/// que o SAP grava, senão a contagem que o conferente vê não é a que fica no
/// log.
const int casasDecimaisQuantidade = 4;

/// Metade da menor fração representável em [casasDecimaisQuantidade].
///
/// A quantidade esperada é uma **soma** de `Menge` em ponto flutuante, e a
/// contada volta do SAP por string — comparar com `==` faria `2.5` divergir de
/// `2.4999999999`, e uma divergência condena a NF-e à devolução.
const double toleranciaQuantidade = 0.00005;

/// `true` quando as duas quantidades são a mesma dentro de
/// [toleranciaQuantidade].
bool quantidadesConferem(double a, double b) =>
    (a - b).abs() < toleranciaQuantidade;

/// Quantidade digitada → número, ou `null` quando não há quantidade.
///
/// Aceita **vírgula ou ponto** como separador decimal: o teclado numérico do
/// coletor mostra um ou outro conforme o locale do Android, e travar o
/// conferente por causa disso custa tempo de doca. Texto vazio, só o
/// separador, negativo ou qualquer coisa que não seja `dígitos[,dígitos]` é
/// `null` — "não informado", que o controller trata como inválido.
double? parseQuantidade(String texto) {
  var limpo = texto.trim().replaceAll(',', '.');
  if (limpo.endsWith('.')) limpo = limpo.substring(0, limpo.length - 1);
  if (limpo.startsWith('.')) limpo = '0$limpo';
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(limpo)) return null;
  return double.tryParse(limpo);
}

/// Quantidade para a tela: sem zeros à direita e com vírgula (`2`, `2,5`,
/// `0,125`).
///
/// `toStringAsFixed` e não `NumberFormat`: não há separador de milhar na
/// contagem, e o `intl` arrastaria locale para dentro do domínio.
String formatarQuantidade(double valor) {
  var texto = valor.toStringAsFixed(casasDecimaisQuantidade);
  if (texto.contains('.')) {
    texto = texto
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
  return texto.replaceFirst('.', ',');
}
