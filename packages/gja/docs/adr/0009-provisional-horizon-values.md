# ADR 0009 — Valores provisórios do tema Horizon

- **Status:** Aceita (protótipo)
- **Data:** 2026-10-28

## Contexto

O GJA adota o SAPUI5 e o tema Horizon do SAP Fiori como modelo de conceitos, nomes e comportamento, sem código nem
assets da SAP. A auditoria de fidelidade de 2026-10-28 abriu uma série de changes de realinhamento da fundação, uma
por fundamento.

Alguns valores exatos do Horizon não podem ser confirmados sem material da SAP: pesos, alturas de linha, raios e
cores de estados específicos. Bloquear cada change até confirmar esses valores travaria o protótipo (ADR 0001).

## Decisão

1. Quando um valor exato do Horizon não puder ser confirmado, o GJA adota o valor mais próximo que seja coerente
   com as regras das specs, como a grade de 4 px e as razões de contraste.
2. O valor fica marcado como provisório na tabela abaixo, com a change que o introduziu.
3. Cada change de realinhamento acrescenta suas linhas a esta ADR, em vez de criar uma ADR por fundamento.
4. Os nomes seguem os parâmetros de tema do SAPUI5 (`sapFontHeader1Size`, `sapContent_Shadow0` etc.) mesmo quando o
   valor é provisório.

### Valores provisórios

| Fundamento | Valor | Adotado | Referência Horizon | Change |
|---|---|---|---|---|
| Tipografia | Peso dos títulos `header1`…`header6` | bold (700) | `sapFontHeaderFamily` | `update-gja-foundation-typography-fiori-sizes` |
| Tipografia | Alturas de linha de todos os estilos | múltiplo de 4 ≥ 1,2 × tamanho (`header1` 48/60) | alturas do Horizon não confirmadas | `update-gja-foundation-typography-fiori-sizes` |
| Tipografia | Família semibold do texto de botões | Inter 600 | `sapButton_FontFamily` (72 semibold duplex) | `update-gja-foundation-typography-fiori-sizes` |
| Estados de interação | Fundo de hover de cada estado de valor | um tom acima do `background` do estado (claro: 100, `none` 200; escuro: 800, `none` 700) | `sapButton_Accept_Hover_Background`, `_Reject_`, `_Attention_` | `update-gja-foundation-interaction-states-fiori-alignment` |
| Estados de interação | Ativo, selecionado e selecionado com hover de Accept, Reject e Attention | normal invertido: fundo e borda `foreground`, texto `background` do estado | `sapButton_Accept_Active_Background` e `_Active_TextColor` (também no Horizon Evening) | `update-gja-foundation-interaction-states-fiori-alignment` |
| Sombras | Geometria de `shadow0`…`shadow3` | `shadow0`: (0, 2) e (2, 4); `shadow1`…`3`: contorno de 1 px e difusa (2, 8), (10, 30) e (20, 80), com fatores de opacidade 1 e 0,5 sobre `colors.shadow` | `sapContent_Shadow0`…`3` (cor de sombra e opacidades por camada não confirmadas) | `update-gja-foundation-elevation-horizon-shadows` |
| Sombras | Papel `dragged` | `shadow3` | o SAPUI5 não define sombra de item arrastado | `update-gja-foundation-elevation-horizon-shadows` |
| Movimento | Durações `short`, `medium` e `long` | 100, 200 e 300 ms (sem mudança) | o SAPUI5 não publica durações como parâmetros de tema | `update-gja-foundation-design-tokens-fiori-motion` |
| Movimento | Efeito dos modos de animação | `basic` = `full`; `minimal` = `none` (durações zero, indeterminado parado) | `sap.ui.core.AnimationMode` (`basic` sem efeitos caros; `minimal` mantém o indicador de ocupado) | `update-gja-foundation-design-tokens-fiori-motion` |
| Densidade | Alvo mínimo (`minTargetSize`) | altura de linha: 44 no cozy, 32 no compacto, aplicada à altura e à largura pela `GjaInteractable` | caixa externa do `sap.m.Button` com `sapElement_LineHeight` (só na altura) | `update-gja-foundation-density-fiori-cozy` |
| Espaçamento | Margem de página por classe de tamanho | 16, 32, 32 e 48 (S, M, L, XL), pela largura da `GjaPage` | `sapUiResponsivePadding` e padding da `sap.f.DynamicPage` (1rem, 2rem, 2rem, 3rem) | `update-gja-foundation-spacing-fiori-margins` |
| Raios | Papéis por tipo de controle | `button` 8, `field` 4, `popover` 8, `element` 12, `tile` 16 | `sapButton_`, `sapField_`, `sapPopover_`, `sapElement_` e `sapTile_BorderCornerRadius` (0.5, 0.25, 0.5, 0.75 e 1rem) | `update-gja-foundation-radius-fiori-roles` |
| Raios | Anel de foco do link | `xs` (2) | contorno de foco do `sap.m.Link`, sem parâmetro próprio | `update-gja-foundation-radius-fiori-roles` |
| Ícones | Tamanho do ícone de controle | 16 | `sapContent_IconHeight` (1rem) | `update-gja-foundation-iconography-fiori-iconpool` |
| Ícones | Nomes do IconPool onde há mais de uma opção | `menu2`, `navBack`, `sysEnter2`, `pending`, `popupWindow` (nomes não conferidos com a versão atual do IconPool) | ícones usados pelo `sap.f.ShellBar`, `sap.m.Page` e `sap.m.MessageStrip` | `update-gja-foundation-iconography-fiori-iconpool` |
| Barra | Altura do `GjaShellBar` | `spacing.xxxl` (48), igual nas duas densidades | `.sapFShellBar { height: 3rem }` | `update-gja-scaffold-fiori-tool-page` |
| Barra | Hover e pressionado dos botões da barra | família `transparent` | `sapShell_Hover_Background` e `sapShell_Active_Background` | `update-gja-scaffold-fiori-tool-page` |
| Barra | Espaço entre elementos da barra | `spacing.xs` | margens internas dos botões do ShellBar, não conferidas | `update-gja-scaffold-fiori-tool-page` |
| Barra | Fundo da `GjaBar` em todos os desenhos | `colors.base` | `sapPageHeader_Background`, `sapPageSubheader_Background` e `sapPageFooter_Background` | `update-gja-page-fiori-page-bar` |
| Barra | Borda e sombra por desenho | `header` com `shadows.header`; `footer` com borda superior `separator`; `floatingFooter` com borda `separator` e raio `radius.s` | `sapContent_HeaderShadow` e estilos do rodapé flutuante do `sap.m.Page` | `update-gja-page-fiori-page-bar` |
| Barra | Espaços da `GjaBar` | `spacing.s` nas pontas e `spacing.xs` entre itens | paddings de 0,25rem dos contêineres da `sap.m.Bar` | `update-gja-page-fiori-page-bar` |
| Página | Fundos de `backgroundDesign` | `standard` e `solid` → `background`; `list` → `base` | classes `sapMPageBg*`, sem conferir o Horizon | `update-gja-page-fiori-page-bar` |
| Cartão | Hover e pressionado do cabeçalho acionável | família `list` | `sapTile_Hover_Background` e `sapTile_Active_Background` | `update-gja-card-fiori-card-header` |
| Cartão | Espaço entre o ícone e os textos do cabeçalho | `spacing.m` | margem do ícone em `CardHeaders.less`, não conferida no Horizon | `update-gja-card-fiori-card-header` |
| Cartão | Cor do subtítulo, do status e da data do cabeçalho | `colors.label` | `sapTile_TextColor` | `update-gja-card-fiori-card-header` |
| Caixa de seleção | Somente leitura: fundo, borda e marca | `colors.background`, `colors.separator`, `colors.label` | `sapField_ReadOnly_Background`, `sapField_ReadOnly_BorderColor`, `sapContent_NonInteractiveIconColor` | `add-gja-check-box` |
| Caixa de seleção | Lado e marca parcial | `icons.control + spacing.xxs` (18); quadrado recuado `spacing.xs` | 1,125rem em `CheckBox.less`; recuo de 0,1875rem | `add-gja-check-box` |
| Chave | Trilho, alça e hover | trilho `2 × icons.medium` × `icons.medium`, alça `icons.control`; hover `label` (desligada) e `brandHover` (ligada) | `Switch.less`; `sapButton_Track_Hover_Background`, `sapButton_Track_Selected_Hover_Background` | `add-gja-switch` |
| Opção de rádio | Lado do círculo e do ponto | círculo `icons.control + spacing.xxs` (18) nas duas densidades; ponto `spacing.s` | 1,375rem (cozy) e 1rem (compacto) em `RadioButton.less` | `add-gja-radio-button` |
| Campo de texto | Somente leitura, foco e mensagem de estado | fundo `headerBackground`; foco com borda `brand` e anel de foco; mensagem em linha abaixo do campo, com o foco | `sapField_ReadOnly_Background`, `sapField_Focus_BorderColor`; mensagem em popup no UI5 | `add-gja-input` |
| Barra de ferramentas | Borda do estilo padrão e fundo da barra de informação | `colors.separator`; `stateColors(information).background` | `sapGroup_TitleBorderColor`; `sapInfobar_Background` | `add-gja-toolbar` |
| Barra de abas | Traço da aba escolhida | `spacing.xxs` (2) em `colors.brand` | 0,1875rem em `IconTabBar.less` | `add-gja-icon-tab-bar` |
| Formulário | Títulos e espaçamentos | formulário H4 e contêiner H5; `spacing.s` entre elementos e antes dos campos, `spacing.xs` sob o rótulo acima, `spacing.l` entre colunas | `ColumnLayout.less`, não conferido no Horizon | `add-gja-form` |
| Tabela | Títulos das colunas, células e `headerText` | `typography.base` em `colors.label`; células com `spacing.s` nas laterais e `spacing.xs` em cima e embaixo; `headerText` H5 | `sapList_HeaderTextColor` e o padding de `Table.less`, não conferidos no Horizon | `add-gja-table` |
| Campo de texto | Ícone padrão da ajuda de valor | `GjaIcons.popupWindow` | `sap-icon://value-help`, sem glifo no conjunto Lucide | `add-gja-date-picker` |
| Seletor de data | Dias do calendário | lado `density.minTargetSize`, raio `radius.field`; escolhido `brand`/`contrastText`, hoje com borda `brand`, outros meses `label` | `sapUiCalendar*` e `Calendar.less`, não conferidos no Horizon | `add-gja-date-picker` |
| Barra de shell | Quando o fim da barra vai para o menu "mais" | na classe de largura S (< 600) | o `OverflowToolbar` do `sap.f.ShellBar` mede o espaço livre | `update-gja-shell-bar-fiori-overflow-menu` |
| Painel | Título, recuo do cabeçalho e espaçamento do conteúdo | `typography.header6`; `spacing.s` antes da seta e `spacing.l` nas laterais; `spacing.l` em volta do conteúdo | `sapMFontHeader6Size` e as margens de `Panel.less`, não conferidos no Horizon | `add-gja-panel` |
| Navegação lateral | Largura expandida e recuo dos subitens | `5 × spacing.xxxl`; `icons.control + spacing.s` por nível | `sapTntSideNavigation_ExpandedWidth`; recuo de `SideNavigation.less`, não conferido | `add-gja-side-navigation` |

## Alternativas consideradas

- **Bloquear até confirmar cada valor.** Rejeitada porque o protótipo não tem acesso ao material de referência
  (ADR 0001).
- **Uma ADR por fundamento.** Rejeitada porque espalharia a mesma política em nove ADRs.

## Consequências

- Os valores provisórios ficam localizados num só lugar e podem ser corrigidos por changes `update-gja-…` quando
  forem confirmados.
- **Condição de saída:** todos os valores da tabela confirmados ou substituídos por uma decisão de identidade
  própria; nesse caso esta ADR é marcada como substituída.
