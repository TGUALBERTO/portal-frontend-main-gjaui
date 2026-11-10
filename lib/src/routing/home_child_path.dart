/// Converte a constante **absoluta** de [AppRoutes] no path **relativo** que a
/// rota-filha da Home exige.
///
/// As telas de feature são declaradas como filhas de `/` (ver `app_router.dart`)
/// para que o Navigator empilhe Home → feature: sem isso o botão voltar do
/// Android não acha nada para desempilhar e **fecha o app**, que era o
/// comportamento até então.
///
/// O go_router só casa uma rota-filha quando o `path` dela é relativo ao pai —
/// filha com `/` inicial simplesmente não resolve. Mas as constantes de
/// [AppRoutes] são (e continuam) absolutas: é o que `context.go` recebe, o que
/// aparece na barra de endereço e o que os deep-links usam. Esta função é a
/// ponte entre as duas formas, para que **a constante siga sendo a fonte
/// única** e nenhuma rota tenha o path duplicado à mão.
///
/// ```dart
/// GoRoute(path: homeChild(AppRoutes.gjaautoInboundContagemCega), ...)
/// //            '/GJAAUTO/IN/contagemCega' -> 'GJAAUTO/IN/contagemCega'
/// ```
String homeChild(String rotaAbsoluta) {
  final semBarra = rotaAbsoluta.startsWith('/')
      ? rotaAbsoluta.substring(1)
      : rotaAbsoluta;
  assert(
    semBarra.isNotEmpty,
    'A Home ("/") não pode ser filha de si mesma — declare-a como o builder do '
    'pai, não em routes:.',
  );
  return semBarra;
}

/// Mesma conversão para uma sub-rota que já está dentro de outra rota-filha.
///
/// A contagem cega tem cinco telas de um fluxo (`/contagemCega/notas/:nota/...`)
/// e cada nível precisa ser relativo ao nível acima, senão a pilha não se
/// reconstrói num deep-link e o voltar pula direto para a Home em vez de
/// recuar uma tela por vez.
///
/// ```dart
/// subRota(AppRoutes.gjaautoInboundContagemCegaNotas,
///         AppRoutes.gjaautoInboundContagemCega)  // -> 'notas'
/// ```
String subRota(String rotaAbsoluta, String rotaDoPai) {
  final pai = rotaDoPai.endsWith('/') ? rotaDoPai : '$rotaDoPai/';
  assert(
    rotaAbsoluta.startsWith(pai),
    '"$rotaAbsoluta" não é sub-rota de "$rotaDoPai" — o go_router não casaria '
    'a filha e a tela ficaria inalcançável.',
  );
  return rotaAbsoluta.substring(pai.length);
}
