# Changelog

## Não lançado

- Pacote renomeado de `rebic_widgets` para `gja_widgets` e tipos `Rebic*` para `Gja*` (ADR 0010).
- Correção: no `GjaForm`, campos que não esticam (como a caixa de seleção) ficam no início da célula, e não
  centrados.
- **BREAKING (leve)** `GjaForm` ganha `editable`, com o padrão `false` do `sap.ui.layout.form.Form`
  (`update-gja-form-fiori-editable`): no modo de exibição, o rótulo ao lado fica alinhado ao topo dos valores;
  formulários com campos de entrada passam `editable: true`.
- `GjaShellBar` ganha `menu` (o título abre um menu, como o `menu` do `sap.f.ShellBar`) e, na classe de largura S,
  leva as notificações e os `GjaButton` de `additionalContent` para um menu "mais"
  (`update-gja-shell-bar-fiori-overflow-menu`).
- `GjaDatePicker`: o mês e o ano do cabeçalho do calendário abrem a escolha de meses e de anos, e
  `showCurrentDateButton` mostra o botão "Hoje" (`update-gja-date-picker-fiori-month-year-today`).
- `GjaTable` ganha `growing`, `growingThreshold` e `growingTriggerText` (botão "Mais" com "[mostradas / total]") e
  títulos de grupo `GjaGroupHeaderListItem` (`update-gja-table-fiori-growing-groups`); `items` passa a
  `List<GjaListItemBase<T>>`.
- **BREAKING** Nomes do SAPUI5 no dropdown (`update-gja-dropdown-fiori-key-text`): `GjaDropdownItem` usa `key` e
  `text` (antes `value` e `label`), e `GjaDropdown` usa `selectedKey` e `onSelectionChange` (antes `selected` e
  `onSelected`). A API do `GjaSelect` não muda.
- **BREAKING** `GjaProgressIndicator` segue só o `sap.m.ProgressIndicator`
  (`update-gja-progress-indicator-fiori-percent-value`): `.linear` e `.circular` dão lugar a
  `GjaProgressIndicator(percentValue:)`, de 0 a 100; saem o modo indeterminado (use `GjaBusyIndicator`), o círculo
  e `size`.
- **BREAKING** `GjaStatusIndicator` passa a se chamar `GjaObjectStatus`
  (`update-gja-status-indicator-fiori-object-status`, spec `gja/widgets/gja-object-status`), o nome do
  `sap.m.ObjectStatus` que ele segue; a API não muda.
- Novo `GjaDatePicker` (`add-gja-date-picker`, spec `gja/widgets/gja-date-picker`), como o
  `sap.m.DatePicker`: `dateValue`, `onChange`, `minDate`, `maxDate`, `placeholder`, `semanticLabel`, `enabled`,
  `editable`, `valueState` e `valueStateText`, com calendário mensal num popover.
- `GjaInput` ganha `showValueHelp`, `valueHelpIconSrc` e `onValueHelpRequest` (`add-gja-date-picker`), como o
  `sap.m.Input`.
- Novo `GjaTable<T>` (`add-gja-table`, spec `gja/widgets/gja-table`), como o `sap.m.Table`: `columns`
  (`GjaColumn` com `hAlign`, `flex`, `minScreenWidth` e `demandPopin`), `items` (`GjaColumnListItem`), `headerText`,
  `noDataText`, `mode`, `selectedKeys`, `onSelectionChange` e `onItemPress`.
- Novo `GjaForm` (`add-gja-form`, spec `gja/widgets/gja-form`), como o `sap.ui.layout.form.Form` com o
  `ColumnLayout`: `title`, `formContainers` (`GjaFormContainer` com `GjaFormElement`), `columnsM`, `columnsL`,
  `columnsXL` e `labelCellsLarge`.
- Novo `GjaPanel` (`add-gja-panel`, spec `gja/widgets/gja-panel`), como o `sap.m.Panel`: `headerText`,
  `content`, `expandable`, `expanded`, `onExpand` e `backgroundDesign`; painéis expansíveis empilhados formam o acordeão.
- Novo `GjaSideNavigation<T>` (`add-gja-side-navigation`, spec `gja/widgets/gja-side-navigation`), como o
  `sap.tnt.SideNavigation`: `items` e `fixedItems` (`GjaNavigationListItem`, com subitens), `selectedKey`,
  `onItemSelect`, `expanded` e `semanticLabel`.
- Novo `GjaIconTabBar<T>` (`add-gja-icon-tab-bar`, spec `gja/widgets/gja-icon-tab-bar`), como o
  `sap.m.IconTabBar`: `items` (`GjaIconTabFilter`), `selectedKey`, `onSelect` e `applyContentPadding`.
- Novo `GjaBreadcrumbs` (`add-gja-breadcrumbs`, spec `gja/widgets/gja-breadcrumbs`), como o
  `sap.m.Breadcrumbs`: `links`, `currentLocationText`, `separatorStyle` e `semanticLabel`.
- Novo `GjaToolbar` (`add-gja-toolbar`, spec `gja/widgets/gja-toolbar`), como o `sap.m.Toolbar`: `content`
  (com `Spacer` e `GjaSeparator.vertical`), `design`, `style`, `onPress`, `enabled` e `semanticLabel`.
- Novo `GjaMessageToast` (`add-gja-message-toast`, spec `gja/widgets/gja-message-toast`), como o
  `sap.m.MessageToast`: `GjaMessageToast.show(context, mensagem)`, que some sozinho depois de 3 segundos.
- Novo `GjaDialog` (`add-gja-dialog`, spec `gja/widgets/gja-dialog`), como o `sap.m.Dialog`: `content`,
  `title`, `state`, `beginButton`, `endButton`, `buttons` e `width`, aberto por `GjaDialog.open` sobre o modal do núcleo.
- Novo `GjaIllustratedMessage` (`add-gja-illustrated-message`, spec `gja/widgets/gja-illustrated-message`),
  como o `sap.m.IllustratedMessage`: `title`, `description`, `illustrationType`, `illustrationSize`, `illustration`,
  `titleLevel` e `additionalContent`.
- Novo `GjaBusyIndicator` (`add-gja-busy-indicator`, spec `gja/widgets/gja-busy-indicator`), como o
  `sap.m.BusyIndicator` e o estado `busy` dos controles: pontos animados, `text` e, com `child`, o conteúdo bloqueado.
- Novo `GjaMessageStrip` (`add-gja-message-strip`, spec `gja/widgets/gja-message-strip`), como o
  `sap.m.MessageStrip`: `text`, `type`, `showIcon`, `showCloseButton`, `onClose` e `link`.
- Novo `GjaSelect<T>` (`add-gja-select`, spec `gja/widgets/gja-select`), como o `sap.m.Select`: controlado
  (`selectedKey` + `onChange`), com os itens de `GjaDropdownItem`, `placeholder`, `enabled`, `editable`,
  `valueState` e `valueStateText`.
- Novo `GjaInput` (`add-gja-input`, spec `gja/widgets/gja-input`), como o `sap.m.Input`: controlado
  (`value` + `onLiveChange`), com `onChange`, `onSubmit`, `placeholder`, `type`, `enabled`, `editable`, `valueState`,
  `valueStateText`, `maxLength`, `showClearIcon` e `focusNode`.
- Novos `GjaRadioButton` e `GjaRadioButtonGroup` (`add-gja-radio-button`), como o `sap.m.RadioButton` e o
  `sap.m.RadioButtonGroup`: opção controlada (`selected` + `onSelect`) e grupo com `selectedIndex`, `onSelect(índice)`,
  `columns`, setas e Tab pela opção marcada.
- Novo `GjaSwitch` (`add-gja-switch`, spec `gja/widgets/gja-switch`), como o `sap.m.Switch`: controlado
  (`state` + `onChange`), com `semanticLabel` e `enabled`.
- Novo `GjaCheckBox` (`add-gja-check-box`, spec `gja/widgets/gja-check-box`), como o `sap.m.CheckBox`:
  controlado (`selected` + `onSelect`), com texto ou `semanticLabel`, `partiallySelected`, `enabled`, `editable`,
  `valueState` e `wrapping`.
- **BREAKING** `enabled` e `onPress` nas ações (`update-gja-actions-fiori-enabled-press`), como os eventos `press` do
  SAPUI5. De/para:
  - `GjaLink(onPressed: ...)` → `GjaLink(onPress: ...)`; `onPressed: null` → `enabled: false`;
  - `GjaMenuItem(label:, onPressed:, shortcut:)` → `GjaMenuItem(text:, onPress:, shortcutText:)`; novo `enabled`;
  - `GjaAvatar` e `GjaStatusIndicator`: `onPressed` → `onPress` (sem ele, continuam não interativos).
- **BREAKING** Botão no modelo do SAPUI5 (`update-gja-button-fiori-button`, spec `gja/widgets/gja-button`, que
  absorve `gja/widgets/gja-icon-button`): um só `GjaButton`, como o `sap.m.Button`. De/para:
  - `GjaButton(label: ..., onPressed: ...)` → `GjaButton(text: ..., onPress: ...)`;
  - `onPressed: null` (desabilitado) → `enabled: false`; `onPress` nulo agora deixa o botão habilitado, sem ação;
  - `GjaIconButton(icon: ..., tooltip: ..., onPressed: ...)` → `GjaButton(icon: ..., tooltip: ..., onPress: ...)`;
    o tipo padrão passa de `transparent` a `standard`, então passe `type: GjaButtonType.transparent` numa barra;
  - novo `tooltip` também no botão com texto, anunciado como dica; `busy` também no botão só com ícone.

  `GjaPage` e `GjaShellBar` usam o novo botão, sem mudança visual. `GjaLink`, `GjaMenuItem`, `GjaAvatar` e
  `GjaStatusIndicator` ainda usam `onPressed`; mudam na próxima change.
- **BREAKING** Grade no modelo do SAPUI5 (`update-gja-grid-fiori-layout-grid`, spec `gja/widgets/gja-grid`),
  como o `sap.ui.layout.Grid`. De/para:
  - `GjaGrid(children: ...)` e `GjaGrid.cells(cells: ...)` → `GjaGrid(content: ...)`;
  - `GjaGridCell(child: x, span: s)` → `GjaGridData(span: s, child: x)`, um widget que envolve o item em `content`;
  - `gap` → `hSpacing`; `runGap` → `vSpacing`;
  - `basis: GjaLayoutBasis.container` → `containerQuery: true`; o padrão passa a medir a classe pela tela
    (`containerQuery: false`), como no UI5;
  - `defaultSpan` padrão `XL3 L3 M6 S12`: na classe `large`, quatro itens por linha em vez de três.
- **BREAKING** HBox e VBox no modelo do SAPUI5 (`update-gja-row-column-fiori-hbox-vbox`, specs
  `gja/widgets/gja-hbox` e `gja/widgets/gja-vbox`, que substituem `gja/widgets/gja-row` e
  `gja/widgets/gja-column`): `GjaRow` passa a `GjaHBox`, e `GjaColumn` a `GjaVBox`, como o `sap.m.HBox` e o
  `sap.m.VBox`. De/para:
  - `children` → `items`; `mainAlignment` → `justifyContent`; `crossAlignment` → `alignItems`; `shrinkWrap` →
    `displayInline`;
  - `GjaRow.wrap(...)` → `GjaHBox(wrap: GjaFlexWrap.wrap, alignItems: GjaFlexAlignItems.start, ...)`;
  - `GjaMainAlignment` → `GjaFlexJustifyContent`, com o novo `spaceAround`; `GjaCrossAlignment` →
    `GjaFlexAlignItems`, com o novo `baseline` (no `GjaVBox`, vale como `start`); novo `GjaFlexWrap`.

  Os padrões de `gap` e `alignItems` não mudam. Com `wrap`, `alignItems` `stretch` e `baseline` disparam uma asserção.
- **BREAKING** Separador no modelo do SAPUI5 (`update-gja-divider-fiori-separator`, spec
  `gja/widgets/gja-separator`, que substitui `gja/widgets/gja-divider`): `GjaDivider` passa a
  `GjaSeparator`, como o `sap.m.ToolbarSeparator`. De/para:
  - `GjaDivider()` → `GjaSeparator()`; `GjaDivider.vertical()` → `GjaSeparator.vertical()`;
  - `tone` e `GjaDividerTone` saem: a linha usa sempre `colors.separator`;
  - `spacing`, `indent` e `endIndent` saem: o espaço vem do contêiner (`gap` de `GjaColumn`, `GjaSpacing`);
  - o vertical deixa de esticar e passa a ter a altura `density.separatorHeight` (32 cozy, 24 compacto), centrado.

  Card, dropdown, menu e popover passam a usar `GjaSeparator`, sem mudança visual.
- Asterisco de obrigatório do `GjaLabel` como no `sap.m.Label` (`update-gja-label-fiori-required`): tamanho
  `large`, negrito, `spacing.xxs` antes e a nova cor `required` magenta. A altura do rótulo não muda.
- **BREAKING** Card e cabeçalho de cartão no modelo do SAPUI5 (`update-gja-card-fiori-card-header`, specs
  `gja/widgets/gja-card` e `gja/widgets/gja-card-header`):
  - `GjaCard` passa à API do `sap.f.Card`: `header`, `headerPosition` (`GjaCardHeaderPosition.top`/`bottom`),
    `content` e `headingLevel` (padrão `h3`). O conteúdo não tem mais margem, como no UI5;
  - novo `GjaCardHeader`, como o `sap.f.cards.Header`: `title` (até 3 linhas, estilo H5), `subtitle` (até 2),
    `statusText`, `statusVisible`, `dataTimestamp`, ícone (`icon`, `iconImage`, `iconInitials`, `iconDisplayShape`,
    `iconSize`, `iconAlt`, `iconVisible`), `toolbar` e `onPress`. Acionável, o título continua anunciado como
    cabeçalho com o nível do cartão.

    | Antes | Agora |
    |---|---|
    | `GjaCard(title:, subtitle:, status:, leading:, onHeaderPressed:, child:)` | `GjaCard(header: GjaCardHeader(title:, subtitle:, statusText:, iconInitials:/icon:, onPress:), content: GjaSpacing.padding(all: GjaSpace.l, child: …))` |
    | `padded: false` | `content` sem `GjaSpacing.padding` |
- **BREAKING** Page e Bar no modelo do SAPUI5 (`update-gja-page-fiori-page-bar`, specs `gja/widgets/gja-page`
  e `gja/widgets/gja-bar`):
  - `GjaPage` passa à API do `sap.m.Page`: `title`, `titleLevel`, `titleAlignment`, `showNavButton`,
    `navButtonTooltip`, `onNavButtonPress`, `headerContent`, `customHeader`, `showHeader`, `subHeader`,
    `showSubHeader`, `content`, `enableScrolling`, `backgroundDesign`, `contentPadding`, `footer`, `showFooter` e
    `floatingFooter`. O cabeçalho é uma `GjaBar` com o título no estilo H5, e o conteúdo não tem espaçamento por
    padrão, como no UI5;
  - novo `GjaBar`, como o `sap.m.Bar`: `contentLeft`, `contentMiddle`, `contentRight`, `design` (`GjaBarDesign`)
    e `titleAlignment` (`GjaTitleAlignment`), com a altura `density.barHeight`.

    | Antes | Agora |
    |---|---|
    | `onBack: f` | `showNavButton: true, onNavButtonPress: f` |
    | `actions: [...]` | `headerContent: [...]` |
    | `body: x` | `content: [x]` (com `contentPadding: GjaContentPadding.responsive` no lugar da margem) |
    | `padded: false` | `contentPadding: GjaContentPadding.none` (o padrão) |
    | `scrollable: false` | `enableScrolling: false` |
    | `footerActions: [...]` | `footer: GjaBar(contentRight: [...])` |
    | `subtitle` | removido (é do `sap.f.DynamicPage`) |
- **BREAKING** ToolPage e ShellBar no modelo do SAPUI5 (`update-gja-scaffold-fiori-tool-page`, specs
  `gja/widgets/gja-tool-page` e `gja/widgets/gja-shell-bar`; `gja/widgets/gja-scaffold` retirada):
  - `GjaScaffold` sai e dá lugar a `GjaToolPage`, como o `sap.tnt.ToolPage`: `header`, `subHeader`,
    `sideContent`, `mainContents`, `sideExpanded` e `onSideExpandedChanged`, com `GjaToolPage.sideExpandedOf` e
    `GjaToolPage.toggleSideContentMode`. O estado automático é decidido na primeira exibição (recolhido só na
    classe `small`) e depois mantido. Na classe `small`, o conteúdo lateral cobre o principal e desliza para fora ao
    recolher. A página não desenha mais separador nem fundo para o conteúdo lateral;
  - novo `GjaShellBar`, como o `sap.f.ShellBar`: voltar, menu, ícone inicial, título e segundo título, pesquisa,
    notificações com contador, conteúdo adicional, perfil e seletor de produtos, cada um com o seu callback.

    | Antes | Agora |
    |---|---|
    | `GjaScaffold(title:, logo:, actions:, navigation:, body:)` | `GjaToolPage(header: GjaShellBar(title:, homeIcon:, additionalContent:, showMenuButton: true, onMenuButtonPressed: …), sideContent:, mainContents: [body])` |
    | `navigationExpanded` / `onNavigationExpandedChanged` | `sideExpanded` / `onSideExpandedChanged` |
    | `GjaScaffold.navigationExpandedOf` | `GjaToolPage.sideExpandedOf` |
    | botão de navegação embutido | botão de menu do `GjaShellBar`, ligado a `GjaToolPage.toggleSideContentMode` |
- **BREAKING** Título, texto e rótulo no modelo do SAPUI5 (`update-gja-text-fiori-title-text-label`, specs
  `gja/widgets/gja-text`, `gja/widgets/gja-title` e `gja/widgets/gja-label`):
  - `GjaText` passa a ser o `sap.m.Text`: `text`, `maxLines`, `wrapping` (padrão `true`) e `textAlign`, sempre com
    `typography.base` e `colors.text`. Saem `variant` (`GjaTextVariant`), `tone` (`GjaTextTone`) e `heading`;
  - novo `GjaTitle`, como o `sap.m.Title`: `level` (semântica) e `titleStyle` (estilo), ambos `GjaTitleLevel`
    (`auto`, `h1`…`h6`), e `wrapping` (padrão `false`, uma linha com reticências);
  - novo `GjaLabel`, como o `sap.m.Label`: `design` (`GjaLabelDesign.standard`/`bold`), `required` (asterisco na
    cor `required`, anunciado como "Obrigatório"), `showColon` e `wrapping` (padrão `false`);
  - `GjaPopover` e `GjaScaffold` usam `GjaTitle`, `GjaTooltip` usa `GjaText` e `GjaStatusIndicator` usa
    `GjaLabel` com `showColon`. `GjaCard`, `GjaPage` e `GjaBadge` desenham o texto com os tokens do tema.
    Nenhum golden desses widgets mudou.

    | Antes | Agora |
    |---|---|
    | `variant: display` / `headline` / `title` / `subtitle` | `GjaTitle` com `titleStyle` `h1` / `h2` / `h3` / `h4` |
    | `variant: body` | `GjaText` |
    | `variant: bodyStrong` | `GjaLabel` com `design: bold`, quando é rótulo |
    | `variant: label` / `caption`, `tone: muted` | `GjaLabel` |
    | `tone: success` / `warning` / `error` / `information` | `GjaStatusIndicator` |
    | `heading: true` | `GjaTitle` (sempre cabeçalho; nível em `level`) |
- **BREAKING** Sobreposições no modelo do Popup do SAPUI5 (`update-gja-core-overlay-fiori-popup`): a propriedade
  `side` (`GjaOverlaySide`, padrão `below`) passa a `placement` (`GjaPlacement`, padrão `bottom`) em
  `GjaPopover`, `GjaMenu`, `GjaDropdown` e `GjaTooltip`, como o `placement` do Popover. As posições padrão
  e a aparência não mudam. O popover acompanha a âncora quando ela muda de tamanho.
- Ícones no modelo do IconPool (`update-gja-foundation-iconography-fiori-iconpool`):
  - os widgets usam os nomes novos de `GjaIcons`: `GjaScaffold` usa `menu2`, `GjaPage` usa `navBack` e o ícone
    padrão de `GjaAvatar` é `personPlaceholder`;
  - ícones de controle (botões, botões de ícone, barra do scaffold, dropdown, menu e o progresso circular padrão)
    passam de 20 a 16;
  - 48 goldens foram regerados.
- **BREAKING** Raios no modelo Fiori (`update-gja-foundation-radius-fiori-roles`):
  - `GjaRadius` (de `GjaContainer`) troca `control` e `container` por `button`, `field`, `popover`, `element` e
    `tile`.
  - `GjaButton` e `GjaIconButton` passam a ter cantos de 8 (`button`), e `GjaCard` de 16 (`tile`).
  - `GjaPopover` usa `popover` (8, sem mudança visual), e o anel de foco de `GjaLink` usa `xs`.
  - Os goldens de botão, botão de ícone, cartão, contêiner, menu e popover foram regerados.
- Espaçamento no modelo Fiori (`update-gja-foundation-spacing-fiori-margins`): `GjaPage` usa a margem de página
  da classe de tamanho da própria largura (16, 32, 32 e 48 de S a XL), como a `sap.f.DynamicPage`, no conteúdo, na
  área de título e no rodapé. Na densidade compacta, os widgets passam a ter o mesmo espaçamento da cozy, e os goldens
  compactos e os da página foram regerados.
- **BREAKING** Densidade no modelo Fiori (`update-gja-foundation-density-fiori-cozy`): `GjaDensity.comfortable`
  passa a `GjaDensity.cozy`, também no parâmetro `density` de `GjaApp`. Botões e botões de ícone medem 36 no cozy
  e 26 no compacto, dentro de uma área de interação de 44 e 32. Os goldens `*_comfortable.png` passam a `*_cozy.png`
  e foram regerados, junto com os compactos que mudaram de medida.
- Movimento no modelo SAPUI5 (`update-gja-foundation-design-tokens-fiori-motion`): as animações usam as curvas CSS
  do SAPUI5. O `animationMode` do tema também desliga a troca animada de `GjaTheme` e a transição de página de
  `GjaApp`, além do pedido do sistema. Os testes de golden de popover, menu e dropdown passam a capturar cada tema
  numa aplicação nova: antes, a troca animada de densidade deixava a sobreposição na posição de um quadro
  intermediário, e os goldens afetados foram regerados.
- **BREAKING** Sombras no modelo Horizon (`update-gja-foundation-elevation-horizon-shadows`): `GjaElevation`
  passa a `GjaShadow`, e a propriedade `GjaContainer.elevation` passa a `shadow`, com os mesmos valores. O popover,
  o menu, o dropdown e a dica passam à sombra `shadow2`, com contorno de 1 px. Os goldens de dica, popover, menu,
  dropdown, cartão e contêiner foram regerados.
- Estados de interação no modelo Fiori (`update-gja-foundation-interaction-states-fiori-alignment`): os botões
  `accept`, `reject` e `attention` de `GjaButton` ficam na própria cor em todos os estados. O hover usa um tom
  claro do estado, em vez do cinza neutro, e o pressionado usa o normal invertido, em vez do azul `highlight`. A API
  não muda, e os goldens existentes não mostram esses estados.
- Tipografia no modelo Fiori (`update-gja-foundation-typography-fiori-sizes`): os widgets passam aos estilos novos
  de `GjaTypographyTokens`, sem mudar a própria API. `GjaText` mapeia cada variante para um estilo Fiori
  (`display` → `header1`, `headline` → `header2`, `title` → `header3`, `subtitle` → `header4`, `body` e `label` →
  `base`, `bodyStrong` → `baseSemibold`, `caption` → `small`); `GjaButton` usa `baseSemibold`; `GjaLink` usa
  `base` e, enfatizado, `baseBold`; `GjaStatusIndicator` usa `base`; `GjaBadge` usa `small`; as iniciais de
  `GjaAvatar` usam `small` e `header4`…`header1`. Títulos ficam em negrito, e os goldens com texto foram regerados.
- `GjaMenu` e `GjaMenuItem` (`add-gja-menu`, spec `gja/widgets/gja-menu`): menu de ações ancorado no modelo
  do `sap.m.Menu`, com ícone, atalho exibido (`shortcut`), seções (`startsSection`), itens desabilitados
  (`onPressed: null`), navegação pelo teclado e papéis semânticos `menu` e `menuItem`. A lista do `GjaDropdown` passa
  para um widget interno compartilhado (`GjaOptionList`), sem mudar a API dele. O mínimo de
  `GjaPopoverWidth.anchor` passa de 4 para 6 passos `spacing.xxxl` (192 no compacto), para que ícone, rótulo e atalho
  caibam.
- `GjaDropdown` e `GjaDropdownItem` (`add-gja-dropdown`, spec `gja/widgets/gja-dropdown`): lista de itens
  selecionáveis num popover ancorado, no modelo da lista do `sap.m.Select`, com ícone, rótulo em uma linha e texto
  adicional, item selecionado, itens desabilitados, cores da família `list`, navegação por setas, Home, End e
  primeira letra, e semântica de botão com estado de selecionado. Novo valor `GjaPopoverWidth.anchor` (largura da
  âncora, no mínimo 6 passos `spacing.xxxl`). Os testes do popover e do tooltip passam a renderizar de fato a
  densidade compacta (o `GjaApp` recebe `density`), e os goldens compactos foram regenerados.
- `GjaPopoverWidth` e `GjaPopover.width` (`update-gja-popover-width`): a largura do popover deixa de seguir o
  conteúdo e passa a ser a do tema, igual entre popovers (`standard`, 8 passos `spacing.xxxl`; `wide`, 12 passos,
  para tabelas), ou a da âncora quando ela é mais larga, como a lista do `sap.m.Select`.
- `GjaPopover` e `GjaPopoverController` (`add-gja-popover`, spec `gja/widgets/gja-popover`): painel
  ancorado no modelo do `sap.m.Popover`, sobre a sobreposição ancorada do núcleo, com superfície `base` sem borda,
  raio `container` e sombra `popover`; cabeçalho opcional com título; conteúdo rolável com ou sem margem; rodapé de
  ações alinhadas ao fim; largura entre 4 e 8 passos `spacing.xxxl`; controlador com `open`, `close`, `toggle` e
  `isOpen`; fechamento por toque fora ou Esc (`onDismiss`); foco preso e semântica de rota nomeada.
- `GjaCard` (`add-gja-card`, spec `gja/widgets/gja-card`): cartão no modelo do `sap.f.Card`, com superfície
  `base`, borda `separator`, raio `container` e sombra `card`; cabeçalho opcional com `leading`, título (variante
  `subtitle`, anunciado como cabeçalho), subtítulo, status e divisor; conteúdo com ou sem margem (`padded`); e
  cabeçalho acionável (`onHeaderPressed`), com hover, teclado e semântica de botão "título, subtítulo".
- Galeria (`fix-gja-gallery-dark-theme`): as 12 páginas dos fundamentos passam a seguir o tema e a densidade
  escolhidos no índice, em vez de tokens claros fixos. As comparações intencionais entre modos e densidades ficam em
  painéis `GalleryComparison`, e um teste abre todas as páginas no tema escuro.
- `GjaAvatar`, `GjaAvatarSize` e `GjaAvatarShape` (`add-gja-avatar`, spec `gja/widgets/gja-avatar`):
  avatar no modelo do `sap.m.Avatar`, com imagem, iniciais (até 3) ou ícone, fallback quando a imagem falha, forma
  circular ou quadrada, cinco tamanhos (1× a 3,5× `icons.xLarge`, os 2/3/4/5/7 rem do UI5), fundo
  `selectionBackground` com `brand`, estado ativo (`onPressed`) e semântica de imagem ou botão.
- `GjaStatusIndicator` (`add-gja-status-indicator`, spec `gja/widgets/gja-status-indicator`): situação de um
  registro no modelo do `sap.m.ObjectStatus`, com `title`, `icon` e `text` na cor de um estado de valor, forma
  invertida (`inverted`), estado ativo (`onPressed`, sublinhado no hover e semântica de botão), quebra de texto com o
  ícone na primeira linha e semântica "título: texto" num só nó.
- `GjaBadge` (`add-gja-badge`, spec `gja/widgets/gja-badge`): contador no modelo do badge dos controles e do
  `count` do `IconTabFilter` do SAPUI5, com as cores de um estado de valor (padrão `error`), limite `max` (`999+`),
  ocultação abaixo de 1, avulso ou centrado no canto superior final de um `child` (sem mudar o tamanho dele nem
  receber toques), e semântica do número, no mesmo nó do elemento.
- `GjaLink` (`add-gja-link`, spec `gja/widgets/gja-link`): link de ação no modelo do `sap.m.Link`, na cor
  `colors.link` (ou `colors.text`, com `subtle`), em negrito com `emphasized`, sublinhado no hover e no pressionado,
  numa linha com reticências ou com quebra (`wrapping`), desabilitado com `onPressed` nulo e anunciado como link.
- `GjaIconButton` (`add-gja-icon-button`, spec `gja/widgets/gja-icon-button`): botão só com ícone, com dica
  obrigatória (rótulo do leitor de tela e `GjaTooltip`), tipos Fiori (padrão `transparent`), estados do núcleo e
  desabilitado. `GjaScaffold` e `GjaPage` passam a usá-lo nos botões de navegação e de voltar, que ganham dica
  visível; o botão interno anterior foi removido. No catálogo, `GjaProgressIndicator`, `GjaTooltip`,
  `GjaButton` e `GjaIconButton` passam a P0/Fase 1, como controles básicos da estrutura das páginas.
- `GjaTooltip`: novo `excludeFromSemantics`, para filhos que já anunciam a mensagem como rótulo; o toque longo
  deixa de expor uma ação sem rótulo na semântica.
- `GjaButton` e `GjaButtonType` (`add-gja-button`, spec `gja/widgets/gja-button`): botão com rótulo, ícone
  opcional, seis tipos no modelo Fiori (`standard`, `emphasized`, `transparent`, `accept`, `reject`, `attention`) sobre
  as famílias de controle, estados do núcleo, desabilitado (`onPressed` nulo) e ocupado (`busy`, com indicador na cor
  do texto e o valor "Carregando" na semântica). A animação do `GjaProgressIndicator` passa a um widget interno
  compartilhado, sem mudança de comportamento.
- `GjaTooltip` (`add-gja-tooltip`, spec `gja/widgets/gja-tooltip`): dica textual de um elemento, aberta pelo
  ponteiro (após `motion.long`), pelo foco do teclado ou por toque longo, e fechada pela saída do ponteiro (após
  `motion.short`), perda de foco, Esc ou toque fora; apontável, uma por vez, posicionada pela sobreposição ancorada
  do núcleo, e anunciada como a dica (`tooltip`) do próprio elemento.
- `GjaProgressIndicator` (`add-gja-progress-indicator`, spec `gja/widgets/gja-progress-indicator`):
  indicador de progresso em barra (`linear`, espessura `spacing.xs`) ou círculo (`circular`, no tamanho de um
  ícone), determinado (`value` de 0 a 1, com transição `motion.short`) ou indeterminado (ciclo de 4 ×
  `motion.long`), com cor por `state`, semântica com o valor em porcentagem e desenho estático no movimento
  reduzido. Primeiro widget da categoria `exibicao-dados`.
- `GjaPage` (`add-gja-page`, spec `gja/widgets/gja-page`): página no modelo do `sap.m.Page`, com área de
  título (`onBack`, `title`, `subtitle`, `actions`) na superfície `base`, conteúdo com a margem `pageMargin`
  (`padded`) que rola entre o título e o rodapé ou recebe a altura disponível (`scrollable: false`), e rodapé fixo
  de ações (`footerActions`). O botão de navegação do `GjaScaffold` passa a usar um botão interno compartilhado,
  sem mudança de comportamento.
- `GjaScaffold` (`add-gja-scaffold`, spec `gja/widgets/gja-scaffold`): estrutura da aplicação no modelo do
  `ToolPage`, com barra superior (`logo`, `title`, `actions` e botão de navegação, na superfície `shell` com sombra
  `header`), navegação lateral expandida ou recolhida ao lado do corpo e, no `small`, sobre o corpo, com estado
  controlado (`navigationExpanded`/`onNavigationExpandedChanged`) ou automático pela classe da tela, e
  `GjaScaffold.navigationExpandedOf`.
- `GjaGrid` (`add-gja-grid`, spec `gja/widgets/gja-grid`): grade de 12 colunas com `defaultSpan` por classe
  de tamanho (padrão `S12 M6 L4 XL3`, com herança), span por item via `GjaGridCell` em `GjaGrid.cells`, fluxo em
  linhas, `gap`/`runGap` por `GjaSpace`, base contêiner ou tela e RTL.
- `GjaResponsiveLayout` (`add-gja-responsive-layout`, spec `gja/widgets/gja-responsive-layout`): um
  construtor por classe de tamanho (`small` obrigatório, demais com herança da classe menor), medido pelo contêiner
  ou pela tela (`GjaLayoutBasis`), com os limiares do tema. Versão básica; colunas flexíveis na Fase 4.
- `GjaDivider` (`add-gja-divider`, spec `gja/widgets/gja-divider`): linha fina horizontal ou vertical
  (`GjaDivider.vertical`), com `tone` (`subtle`/`strong`), `spacing` e recuo direcional (`indent`/`endIndent`) por
  `GjaSpace`; fora da semântica.
- `GjaRow` e `GjaColumn` (`add-gja-row-column`, specs `gja/widgets/gja-row` e `gja/widgets/gja-column`):
  `gap` (`GjaSpace`, só entre filhos), `GjaMainAlignment`, `GjaCrossAlignment` e `shrinkWrap`, sobre o
  `spacing` nativo do `Flex`; `GjaRow.wrap` quebra em linhas e rejeita filhos expansíveis.
- `GjaContainer` (`add-gja-container`, spec `gja/widgets/gja-container`): superfície com `surface`
  (`GjaSurface`), `border` (`separator`), `radius` (`GjaRadius`, com recorte do conteúdo), `elevation`
  (`GjaElevation`, papéis de sombra) e `padding` (`GjaSpace`), todos do tema ativo. O suporte de goldens dos
  testes passa a aceitar a superfície de fundo.
- `GjaSpacing` (`add-gja-spacing`, spec `gja/widgets/gja-spacing`): espaço nomeado por `GjaSpace` (passos e
  papéis de layout do tema), com `GjaSpacing.horizontal`, `.vertical`, `.padding` (precedência por lado e
  início/fim pela direção do texto) e `GjaSpacing.resolve`; os valores seguem a densidade ativa.
- `GjaIcon` (`add-gja-icon`, spec `gja/widgets/gja-icon`): ícone com `size` (papéis de `GjaIconTokens`),
  `tone` (texto, rótulo, marca ou estado de valor) e `semanticLabel` (sem ele, decorativo); direcionais espelhados em
  RTL e `inline` acompanhando a escala de texto. Os testes passam a carregar também a Lucide.
- `GjaText` (`add-gja-text`, spec `gja/widgets/gja-text`): texto com `variant` (escala tipográfica), `tone`
  (texto, rótulo ou estado de valor), `maxLines` com reticências, `textAlign` e semântica de cabeçalho nas variantes
  de título.
- Infraestrutura de goldens: fonte Inter nos testes, etiqueta `golden` e referência gerada no Windows (ADR 0008).
- `GjaApp` (`add-gja-app`, spec `gja/widgets/gja-app`): raiz da aplicação sobre `WidgetsApp`, sem Material,
  com navegação por rotas ou `GjaApp.router`, `theme`/`darkTheme` e `GjaThemeMode` (segue o brilho do sistema),
  densidade recomendada pela plataforma, localização do GJA, escopo de tela, fundo `background` e transição de
  página deslizando do lado final (imediata com movimento reduzido).
- `GjaTheme` (`add-gja-theme`, spec `gja/widgets/gja-theme`), primeiro widget público: aplica o tema à
  subárvore com troca animada, `GjaTheme.density` troca a densidade de uma subárvore, e o texto e o ícone padrão
  seguem o tema.

## 0.0.1

- Estrutura inicial do pacote (Fase 0). Sem API pública.
