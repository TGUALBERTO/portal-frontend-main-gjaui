# Changelog

## Não lançado

- Pacote renomeado de `rebic_core` para `gja_core` e tipos `Rebic*` para `Gja*` (ADR 0010).
- Meses e anos do calendário (`update-gja-date-picker-fiori-month-year-today`, spec `gja/core/localization`):
  `monthNames`, `formatYear` e o texto `today`.
- Datas do calendário (`add-gja-date-picker`, spec `gja/core/localization`): `parseDate`, `datePattern`,
  `formatMonthYear`, `formatLongDate`, `firstDayOfWeek`, `shortWeekdays` e os textos `previous` e `next`.
- Textos `selectAll` e `selectItem` (`add-gja-table`, spec `gja/core/localization`), as caixas de seleção da
  tabela.
- Semântica de marcação e alternância (`add-gja-check-box`, spec `gja/core/interaction`): `GjaInteractable`
  ganha `checked`, `mixed`, `toggled` e `inMutuallyExclusiveGroup`; com eles, o elemento é exposto como caixa, chave
  ou opção de rádio, e não como botão.
- Textos `menu`, `logo`, `notifications`, `profile`, `products` e `shellBar` (`update-gja-scaffold-fiori-tool-page`,
  spec `gja/core/localization`), como os textos do `sap.f.ShellBar`. Quem estende `GjaLocalizations` passa a
  implementá-los.
- **BREAKING** Sobreposições no modelo do Popup do SAPUI5 (`update-gja-core-overlay-fiori-popup`, spec
  `gja/core/overlay`):
  - `GjaModal.show` fecha só com Esc (com `dismissible`), como o `sap.m.Dialog`. A camada de bloqueio nunca é
    interativa: o toque nela é ignorado, e ela não tem rótulo nem ação na semântica. `barrierColor` passa a
    `blockLayerColor`.
  - `GjaOverlaySide` (`below`, `above`, `start`, `end`) passa a `GjaPlacement` (`bottom`, `top`, `start`,
    `end`), e `GjaAnchoredOverlay.side` passa a `placement`, como o `placement` do Popover.
  - `GjaAnchoredOverlay` acompanha a âncora quando ela se move ou muda de tamanho, e não só na rolagem.
  - Novo `GjaAnchoredOverlay.placementOf(context)`, com a posição efetiva depois da inversão.
- Raios no modelo Fiori (`update-gja-foundation-radius-fiori-roles`, spec `gja/core/interaction`): o anel de foco
  de `GjaInteractable` usa por padrão o raio `button` do tema (`sapButton_BorderCornerRadius`), no lugar de
  `control`.
- **BREAKING** Densidade no modelo Fiori (`update-gja-foundation-density-fiori-cozy`, spec `gja/core/responsive`):
  `GjaResponsive.recommendedDensity` recomenda `GjaDensity.cozy` (antes `comfortable`) em Android, iOS e
  Fuchsia. A área mínima de `GjaInteractable` passa a 44 no cozy e a 32 no compacto, pelos tokens de densidade.
- Interação (`add-gja-link`): `GjaInteractable.link` expõe o papel de link em vez do de botão ao leitor de tela,
  com o padrão `false` inalterado.
- Localização (`add-gja-page`): novo texto `back` ("Voltar" / "Back"), rótulo do botão de voltar da `GjaPage`.
  Subclasses próprias de `GjaLocalizations` precisam implementá-lo.
- Localização (`add-gja-scaffold`): novo texto `navigation` ("Navegação" / "Navigation"), rótulo do botão de
  navegação do `GjaScaffold`. Subclasses próprias de `GjaLocalizations` precisam implementá-lo.
- Valores do tema ativo (`add-gja-theme`): os parâmetros visuais de `GjaInteractable` (`minTargetSize`,
  `interactionTokens`, `focusColor`, `focusRingBorderRadius`), `GjaModal.show` (`barrierColor`),
  `GjaAnchoredOverlay` (`gap`, `margin`) e da responsividade (`breakpoints`) passam a ser opcionais e, sem valor,
  vêm de `GjaThemeData.of`. O anel de foco sem raio informado passa a usar o raio `control` do tema (antes, zero).

- Sobreposições (`add-gja-core-overlay`, spec `gja/core/overlay`):
  - `GjaModal.show`: modal com camada de bloqueio (`blockLayer`), foco preso e devolvido, dispensa por Esc e pela
    camada quando dispensável, e resultado ao fechar;
  - `GjaAnchoredOverlay` e `GjaAnchoredOverlayController`: conteúdo junto de uma âncora, com lado preferido
    (`GjaOverlaySide`), alinhamento (`GjaOverlayAlignment`), inversão sem espaço, limite de bordas, rolagem
    acompanhada, fechamento automático por toque fora e Esc, e foco devolvido à âncora;
  - empilhamento nativo: a sobreposição aberta dentro de um modal fica acima dele, e Esc fecha só a do topo.

- Responsividade (`add-gja-core-responsive`, spec `gja/core/responsive`):
  - `GjaResponsive.screenSizeClassOf`: classe de tamanho da largura da janela;
  - `GjaScreenSizeScope`: publica a classe da tela e só reconstrói quem a lê quando a classe muda;
  - `GjaResponsiveBuilder`: classe de tamanho do espaço disponível para o próprio widget;
  - `GjaResponsiveValue<T>`: valor por classe, com herança da classe menor (como os spans `XL/L/M/S` do UI5);
  - `GjaResponsive.recommendedDensity`: compacta em desktop, confortável em dispositivos de toque.

- Localização (`add-gja-core-localization`, spec `gja/core/localization`):
  - `GjaLocalizations` com os textos do framework (ações comuns, vazio, carregando, obrigatório, estados de valor e
    contagem de selecionados) e as implementações `GjaLocalizationsPtBr` (padrão) e `GjaLocalizationsEn`;
  - `GjaLocalizations.delegate`, `supportedLocales` e `of(context)`, que recorre ao pt-BR sem o delegate;
  - formatação por idioma: `formatDecimal`, `formatInteger`, `formatDate`, `formatTime` e `formatDateTime`;
  - nova dependência `intl` 0.20.2, a versão fixada pelo Flutter SDK.

- **BREAKING** `GjaInteractable` lê `focusWidth` e `focusOffset` de `GjaInteractionStateTokens` (antes
  `focusRingWidth` e `focusRingOffset`), conforme o realinhamento ao Fiori do `gja_foundation`.

- Interação e foco (`add-gja-core-interaction`, spec `gja/core/interaction`):
  - `GjaInteractable`: estados (hover, pressionado, foco, selecionado, desabilitado), ativação por toque e por
    Enter/Espaço, área mínima de interação, semântica de botão e cursor de clique;
  - `GjaFocusRing`: anel de foco desenhado fora do conteúdo, só com foco por teclado.

## 0.0.1

- Estrutura inicial do pacote (Fase 0). Sem API pública.
