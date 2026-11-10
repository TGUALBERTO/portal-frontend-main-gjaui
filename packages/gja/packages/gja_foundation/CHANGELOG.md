# Changelog

## Não lançado

- Pacote renomeado de `rebic_foundation` para `gja_foundation` e tipos `Rebic*` para `Gja*` (ADR 0010).
- 95 ícones novos em `GjaIcons` (spec `gja/foundation/iconography`), para cobrir os ícones do portal GJA:
  pessoas e grupos, agenda, cadeados, documentos, chamados, veículos, filas, gráficos, nuvem, mídia e outros. Os
  nomes são do IconPool do SAPUI5 em camelCase, conferidos com o `SAP-icons.json` v5 do `@ui5/webcomponents-icons`,
  e os desenhos são da Lucide empacotada, um glifo por ícone. `journeyArrive`, `sysFirstPage` e `sysLastPage` são
  direcionais.
- Token de densidade `separatorHeight` (`update-gja-divider-fiori-separator`, spec `gja/foundation/density`):
  altura do separador vertical, como a do `sap.m.ToolbarSeparator`, 32 no cozy e 24 no compacto, com o primitivo
  `GjaDensityPrimitives.size24`. Quem cria `GjaDensityTokens` pelo construtor passa a informar `separatorHeight`.
- Escala primitiva `magenta` (`update-gja-label-fiori-required`, spec `gja/foundation/color`): o papel `required`
  passa de vermelho a `magenta600` (claro) e `magenta300` (escuro), como o `sapField_RequiredColor` do Horizon, com
  valores próprios.
- Token de densidade `barHeight` (`update-gja-page-fiori-page-bar`, spec `gja/foundation/density`): altura do
  `sap.m.Bar`, 48 no cozy e 32 no compacto, com o primitivo `GjaDensityPrimitives.size48`. Quem cria
  `GjaDensityTokens` pelo construtor passa a informar `barHeight`.
- Ícone `grid` em `GjaIcons` (`update-gja-scaffold-fiori-tool-page`): seletor de produtos do `GjaShellBar`,
  com o `grip` da Lucide e o nome `grid` do IconPool.
- Papel de cor `required` (`update-gja-text-fiori-title-text-label`, spec `gja/foundation/color`): cor do
  asterisco de rótulo obrigatório, como o `sapField_RequiredColor`, com contraste ≥ 4,5:1 sobre `background`, `base`
  e `headerBackground`. Valor provisório no ADR 0009. Quem cria `GjaColorTokens` pelo construtor passa a informar
  `required`.
- **BREAKING** Breakpoints no modelo SAPUI5 (`update-gja-foundation-breakpoints-fiori-ranges`, spec
  `gja/foundation/breakpoints`): `GjaBreakpointPrimitives` passa a ter só `width600`, `width1024` e `width1440`, os
  limites das faixas do `sap.ui.Device.media` (`SAP_STANDARD_EXTENDED`). Saem `width360`, `width840`, `width1280` e
  `width1920`. O dartdoc de `GjaSizeClass` cita as faixas S, M, L e XL (Phone, Tablet, Desktop e LargeDesktop).
- **BREAKING** Ícones no modelo do IconPool (`update-gja-foundation-iconography-fiori-iconpool`, spec
  `gja/foundation/iconography`): `GjaIcons` passa aos nomes do IconPool do SAPUI5 em camelCase. Os desenhos
  continuam os da Lucide.

    | Antes | Agora | Antes | Agora |
    |---|---|---|---|
    | `close` | `decline` | `clock` | `pending` |
    | `check` | `accept` | `user` | `personPlaceholder` |
    | `chevronUp`/`Down`/`Left`/`Right` | `slimArrowUp`/`Down`/`Left`/`Right` | `settings` | `actionSettings` |
    | `arrowLeft` | `navBack` | `externalLink` | `popupWindow` |
    | `arrowRight` | `navigationRightArrow` | `visibility` | `show` |
    | `menu` | `menu2` | `visibilityOff` | `hide` |
    | `moreHorizontal` | `overflow` | `logout` | `log` |
    | `info` | `information` | `notification` | `bell` |
    | `success` | `sysEnter2` | `file` | `document` |
    | `help` | `sysHelp` | `folder` | `folderBlank` |

  - Os nomes `add`, `search`, `edit`, `delete`, `warning`, `error`, `calendar`, `filter`, `sort`, `upload`,
    `download`, `refresh`, `home` e `copy` não mudam.
  - `moreVertical` foi removido: o IconPool não tem reticências verticais.
  - Novo `GjaIcons.iconPoolNames`, com o nome `sap-icon://` de cada ícone.
  - `GjaIconTokens.control` passa de 20 a 16 (`sapContent_IconHeight`).

  Valores provisórios na ADR 0009.
- **BREAKING** Raios no modelo Fiori (`update-gja-foundation-radius-fiori-roles`, spec `gja/foundation/radius`):
  os papéis `control` e `container` de `GjaRadiusTokens` dão lugar aos raios por tipo de controle do Horizon.

    | Papel | Parâmetro Fiori | Referência |
    |---|---|---|
    | `button` | `sapButton_BorderCornerRadius` | 8 |
    | `field` | `sapField_BorderCornerRadius` | 4 |
    | `popover` | `sapPopover_BorderCornerRadius` | 8 |
    | `element` | `sapElement_BorderCornerRadius` | 12 |
    | `tile` | `sapTile_BorderCornerRadius` | 16 |

  Antes, `control` valia 4 e `container` valia 8. Valores provisórios na ADR 0009.
- Espaçamento no modelo Fiori (`update-gja-foundation-spacing-fiori-margins`, specs `gja/foundation/spacing` e
  `gja/foundation/density`):
  - `GjaSpacingTokens` ganha `pageMarginMedium`, `pageMarginLarge`, `pageMarginExtraLarge` e
    `pageMarginFor(GjaSizeClass)`, com 16, 32, 32 e 48 na referência (`sapUiResponsivePadding`). `pageMargin`
    continua sendo a margem da classe S.
  - O dartdoc dos passos `s`, `l`, `xxl` e `xxxl` cita as classes de margem `sapUiTinyMargin`…`sapUiLargeMargin`.
  - **BREAKING (visual)** A densidade compacta passa a usar o espaçamento de referência. A densidade muda só as alturas
    de elemento, como no Fiori.

  Valores provisórios na ADR 0009.
- **BREAKING** Densidade no modelo Fiori (`update-gja-foundation-density-fiori-cozy`, spec `gja/foundation/density`):
  `GjaDensity.comfortable` passa a `GjaDensity.cozy` (`sapUiSizeCozy`), e `GjaDensityTokens.comfortable()` a
  `GjaDensityTokens.cozy()`. Medidas dos parâmetros `sapElement_*`:

    | | Cozy (antes → agora) | Compact (antes → agora) |
    |---|---|---|
    | `controlHeight` | 40 → 36 | 32 → 26 |
    | `listItemHeight` | 48 → 44 | 32 |
    | `minTargetSize` | 48 → 44 | 24 → 32 |

  - Novos primitivos `GjaDensityPrimitives` (`size26`, `size32`, `size36`, `size44`).
  - `GjaAccessibility.defaultMinTargetSize` passa a 44.
  - A regra "o rótulo cabe no controle" passa a usar a linha de `base` mais 2 × `xxs`.

  Valores provisórios na ADR 0009.
- **BREAKING** Movimento no modelo SAPUI5 (`update-gja-foundation-design-tokens-fiori-motion`, specs
  `gja/foundation/design-tokens`, `gja/foundation/accessibility` e `gja/foundation/theming`):

    | Antes | Agora |
    |---|---|
    | `GjaMotionPrimitives.curveStandard` `(0.4, 0, 0.2, 1)` | `curveEaseInOut` `(0.42, 0, 0.58, 1)` |
    | `GjaMotionPrimitives.curveDecelerate` `(0, 0, 0.2, 1)` | `curveEaseOut` `(0, 0, 0.58, 1)` |
    | `GjaMotionPrimitives.curveAccelerate` `(0.4, 0, 1, 1)` | `curveEaseIn` `(0.42, 0, 1, 1)` |
    | `GjaAccessibility.resolveMotion(motion, disableAnimations:)` | `resolveMotion(motion, mode:)` |

  - Os papéis `standard`, `enter` e `exit` passam às curvas CSS `ease-in-out`, `ease-out` e `ease-in`; novo mapa
    `GjaMotionPrimitives.curves`.
  - Novo `GjaAnimationMode` (`full`, `basic`, `minimal`, `none`), como `sap.ui.core.AnimationMode`, com
    `reducesMotion` e `effective`.
  - `GjaThemeData.animationMode` (padrão `full`). `resolve` e `of` aplicam o modo efetivo: o do tema ou, com
    animações desligadas na plataforma, `none`.

  Valores provisórios na ADR 0009.
- **BREAKING** Sombras no modelo Horizon (`update-gja-foundation-elevation-horizon-shadows`, spec
  `gja/foundation/shadows`, que substitui `gja/foundation/elevation`):

    | Antes | Agora |
    |---|---|
    | `src/elevation/` | `src/shadows/` |
    | `GjaElevationTokens` | `GjaShadowTokens` |
    | `GjaElevationPrimitives.shadows` | `GjaShadowPrimitives.values` |
    | `GjaThemeData.elevation` | `GjaThemeData.shadows` |
    | `shadowsFor(level, color)` | `boxShadows(shadow, color)` |

  - Geometria dos parâmetros `sapContent_Shadow*`: `shadow0` com duas camadas difusas curtas; `shadow1` a `shadow3`
    com contorno de 1 px e uma camada difusa (2/8, 10/30 e 20/80). Sai o par "contato + ambiente" do Material.
  - Papéis como no Horizon: `popover` passa de `shadow1` a `shadow2`, `dialog` de `shadow2` a `shadow3`, e `dragged`
    fica em `shadow3`.

  Valores provisórios na ADR 0009.
- **BREAKING** Estados de interação no modelo Fiori (`update-gja-foundation-interaction-states-fiori-alignment`,
  specs `gja/foundation/interaction-states` e `gja/foundation/color`):
  - `GjaInteractionState.dragged` removido. O item arrastado usa a sombra `dragged` de elevação e as cores de
    `pressed`.
  - `GjaInteractionPrimitives` fica só com `opacity40` (`sapContent_DisabledOpacity`). Saem `opacity0`, `opacity4`,
    `opacity8`, `opacity12`, `opacity16`, `opacity24`, `opacity50` e `opacity100`.
  - `GjaValueStateColors` ganha o papel obrigatório `hoverBackground`, um tom acima do `background` do estado
    (como `sapButton_Accept_Hover_Background`). `gjaCheckContrast` passa a medir o `foreground` sobre ele.
  - As famílias `accept`, `reject` e `attention` usam só as cores do estado de valor: hover com o `hoverBackground`
    do estado, e ativo, selecionado e selecionado com hover com o normal invertido (`foreground` de fundo e borda,
    `background` de texto). Antes, usavam o `hoverBackground` neutro e o `highlight` da marca.

  Valores provisórios na ADR 0009.
- **BREAKING** Tipografia no modelo Fiori (`update-gja-foundation-typography-fiori-sizes`, spec
  `gja/foundation/typography`): os estilos de `GjaTypographyTokens` passam aos nomes dos parâmetros de tamanho de
  fonte do SAPUI5 (`sapFontHeader1Size`…`6Size`, `sapFontLargeSize`, `sapFontSize`, `sapFontSmallSize`), com títulos em
  negrito; novos primitivos `size48` e `lineHeight60`. Valores provisórios na ADR 0009.

    | Antes | Agora |
    |---|---|
    | `display` (40/48, 600) | `header1` (48/60, 700) |
    | `headline` (32/40, 600) | `header2` (32/40, 700) |
    | `title` (24/32, 600) | `header3` (24/32, 700) |
    | `subtitle` (18/24, 600) | `header4` (20/24, 700) |
    | `body` | `base` |
    | `bodyStrong` | `baseSemibold` |
    | `label` (14/20, 500) | `base` (rótulos se distinguem pela cor `label`) |
    | `caption` | `small` |
    | — | novos: `header5` (16/20), `header6` (14/20), `large` (16/24), `baseBold` (14/20, 700) |
- Estados de interação (`add-gja-button`): famílias de controle `accept`, `reject` e `attention`, derivadas das cores
  dos estados de valor `success`, `error` e `warning`, para os tipos de botão Accept, Reject e Attention do Fiori.
- Tema na árvore (`add-gja-theme`, spec `gja/foundation/theming`): `GjaThemeScope` publica o tema para a
  subárvore, e `GjaThemeData.of`/`maybeOf` leem o tema ativo, com o claro de referência como reserva e o movimento
  reduzido quando o sistema pede.

- **BREAKING** Realinhamento ao modelo Fiori (`update-gja-foundation-color-fiori-parameters`, specs
  `gja/foundation/color`, `gja/foundation/interaction-states` e `gja/foundation/theming`):
  - papéis de cor renomeados e ampliados em `GjaColorTokens`, com o mapa `roles`:

    | Antes | Agora |
    |---|---|
    | `surface` | `base` |
    | `surfaceVariant` | `headerBackground` |
    | `onSurface` | `text` |
    | `onSurfaceMuted` | `label` |
    | `border` | `separator` |
    | `borderStrong` | `fieldBorder` |
    | `primary` | `brand` |
    | `onPrimary` | `contrastText` |
    | `primaryContainer` | `selectionBackground` |
    | `scrim` | `blockLayer` |
    | `onSurfaceDisabled`, `surfaceDisabled`, `onPrimaryContainer` | removidos (desabilitado usa `disabledOpacity`) |
    | — | novos: `shell`, `link`, `brandHover`, `highlight`, `hoverBackground`, `selectionHoverBackground` |

  - primitiva `GjaColorPrimitives.transparent`;
  - famílias de controle `GjaControlFamily` (`standard`, `emphasized`, `transparent`, `list`), com
    `GjaStateColors`, `GjaControlColors.of` e `resolve`, no lugar da camada de estado;
  - `GjaInteractionStateTokens` passa a ter só `disabledOpacity` (0,4), `focusWidth` e `focusOffset`; saem
    `hover`, `pressed`, `selected`, `dragged`, `overlayOpacity`, `overlayColor`, `maxOverlayOpacity`,
    `elevationLevel` e `focusRingWidth`/`focusRingOffset`. A primitiva `opacity38` vira `opacity40`;
  - `gjaCheckStateContrast`, somada a `gjaCheckContrast` em `GjaThemeData.accessibilityIssues()`.
- **BREAKING** Sombras no modelo Fiori (`update-gja-foundation-elevation-fiori-shadows`, spec
  `gja/foundation/elevation`):

  | Antes (primitivo / semântico) | Agora |
  |---|---|
  | `elevation0` / `level0` | `none` |
  | `elevation1` / `level1` | `shadow0` |
  | `elevation2` / `level2` | `shadow1` |
  | `elevation3` / `level3` | `shadow2` |
  | `elevation4` / `level4` | `shadow3` |
  | `GjaElevationPrimitives.levels` | `GjaElevationPrimitives.shadows` |
  | — | novos: primitivo `header`; papéis `dragged` (= `shadow3`) e `header` |

- Design tokens (`add-gja-foundation-design-tokens`, spec `gja/foundation/design-tokens`):
  - contrato `GjaTokenSet<T>` (imutável, `copyWith`, `lerp`, igualdade por valor, diagnóstico);
  - tokens de movimento: primitivos `GjaMotionPrimitives` e papéis semânticos `GjaMotionTokens`;
  - extensões tipadas da aplicação: `GjaTokenExtension<T>` e `GjaTokenExtensions`;
  - nova biblioteca `package:gja_foundation/gja_primitives.dart`, não reexportada por `gja_ui`.
- Cores (`add-gja-foundation-color`, spec `gja/foundation/color`):
  - escalas primitivas `GjaColorPrimitives` (paleta provisória própria: neutro, azul, verde, âmbar, vermelho e ciano);
  - papéis semânticos `GjaColorTokens`, com mapeamentos de referência `light()` e `dark()`;
  - estado semântico de valor `GjaValueState` e suas cores (`GjaValueStateColors`);
  - contraste WCAG 2.1: `gjaContrastRatio`, `gjaContrastRatioOver` e `gjaCheckContrast`.
- Espaçamentos (`add-gja-foundation-spacing`, spec `gja/foundation/spacing`):
  - escala primitiva `GjaSpacingPrimitives` (grade de 4 px, de 0 a 64);
  - passos e papéis de layout `GjaSpacingTokens`, com o mapeamento confortável `fallback()`.
- Tipografia (`add-gja-foundation-typography`, spec `gja/foundation/typography`):
  - fonte Inter 4.1 empacotada (pesos 400–700; SIL Open Font License 1.1 em `fonts/inter/OFL.txt`). Aumenta o
    bundle das aplicações em cerca de 1,6 MB;
  - primitivos `GjaTypographyPrimitives` (família, fallbacks, tamanhos, alturas de linha e pesos);
  - estilos semânticos `GjaTypographyTokens` (`display` a `caption`), sem cor, com o mapeamento `fallback()`.
- Raios de borda (`add-gja-foundation-radius`, spec `gja/foundation/radius`):
  - escala primitiva `GjaRadiusPrimitives` (0 a 16 px e `radiusFull` para pílula);
  - passos e papéis `GjaRadiusTokens` (`control`, `container`), com o mapeamento `fallback()`.
- Breakpoints (`add-gja-foundation-breakpoints`, spec `gja/foundation/breakpoints`):
  - escala primitiva `GjaBreakpointPrimitives` (360 a 1920 px);
  - classes de tamanho `GjaSizeClass` (`small` a `extraLarge`), com `isAtLeast`/`isAtMost`;
  - limiares `GjaBreakpointTokens` (600, 1024 e 1440 no `fallback()`), com `classify` e `minWidthOf`.
- Ícones (`add-gja-foundation-iconography`, spec `gja/foundation/iconography`):
  - fonte de ícones Lucide 1.61.0 empacotada (licença ISC em `fonts/lucide/LICENSE`, com o mapa oficial
    `codepoints.json`); o *tree shaking* de ícones a reduz em builds de release;
  - catálogo semântico `GjaIcons` (38 ícones `const`, direcionais espelhados em RTL), com `all` e `lucideNames`;
  - primitivos `GjaIconPrimitives` (família, pacote e tamanhos 12–48) e tamanhos `GjaIconTokens`
    (`inline` e `control`), com o mapeamento `fallback()`.
- Densidade (`add-gja-foundation-density`, spec `gja/foundation/density`):
  - modos `GjaDensity` (`comfortable`, `compact`);
  - `GjaDensityTokens` com altura de controle, altura de item, alvo mínimo (48/24) e espaçamento por densidade,
    com os mapeamentos `comfortable()`, `compact()` e `of(densidade)`.
- Elevação (`add-gja-foundation-elevation`, spec `gja/foundation/elevation`):
  - camada de sombra `GjaShadowLayer` (geometria sem cor) e níveis primitivos `GjaElevationPrimitives` (0 a 4);
  - níveis e papéis `GjaElevationTokens` (`card`, `popover`, `dialog`), com `shadowsFor(nível, cor)` usando a
    cor `shadow` do tema.
- Estados de interação (`add-gja-foundation-interaction-states`, spec `gja/foundation/interaction-states`):
  - primitivos `GjaInteractionPrimitives` (opacidades e espessuras de traço) e estados `GjaInteractionState`;
  - `GjaInteractionStateTokens`: camada de estado (hover 8%, pressionado 12%, selecionado 12%, arrastado 16%,
    teto de 16%), anel de foco (2 px), opacidade de desabilitado (38%) e elevação em interação, com as regras
    `overlayOpacity`, `overlayColor`, `showsFocusRing` e `elevationLevel`.
- Acessibilidade (`add-gja-foundation-accessibility`, spec `gja/foundation/accessibility`):
  - convenções `GjaAccessibility`: meta WCAG 2.2 AA, mínimos de contraste (os de cor), escala de texto suportada
    (200%), alvo mínimo por densidade e `resolveMotion` para movimento reduzido;
  - o template de spec de widget passa a exigir a bateria mínima de testes de acessibilidade.
- Tema (`add-gja-foundation-theming`, spec `gja/foundation/theming`):
  - `GjaThemeData` reúne brilho e todos os conjuntos de tokens, com `components` (tokens de componente) e
    `extensions` (tokens da aplicação);
  - temas de referência `light()`/`dark()` com densidade, `withDensity`, `resolve(disableAnimations:)`,
    `accessibilityIssues()` e interpolação entre temas.
- `GjaAccessibility.defaultMinTargetSize` (48), alvo mínimo padrão para parâmetros (`add-gja-core-interaction`).

## 0.0.1

- Estrutura inicial do pacote (Fase 0). Sem API pública.
