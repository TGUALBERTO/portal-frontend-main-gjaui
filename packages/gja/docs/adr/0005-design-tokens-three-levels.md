# ADR 0005 — Design tokens em três níveis

- **Status:** Aceita
- **Data:** 2026-10-24

## Contexto

A aparência deve ser centralizada no design system e personalizável por um tema único.
Os widgets não podem conter valores visuais literais (spec `gja/framework-architecture`).

## Decisão

1. **Primitivos:** escalas brutas (cores, tipografia, espaçamento, raios, sombras, durações).
   Os widgets **não** os leem.
2. **Semânticos:** papéis (`base`, `text`, `brand`, `separator`, `focus`, estados de valor,
   estilos de texto). Cada tema (claro/escuro/marca) mapeia os primitivos para esses papéis.
3. **De componente:** derivados dos semânticos e agrupados por widget dentro do `GjaThemeData`.

Os widgets leem apenas os níveis 2 e 3. A personalização é feita com `copyWith` sobre `GjaThemeData`
e com extensões tipadas para tokens da aplicação.
`gja_checks tokens` impede literais visuais em `packages/gja_widgets/lib`.
As exceções ficam em `tool/gja_checks/token_exceptions.yaml`, cada uma com justificativa.

## Alternativas consideradas

- **Nível único de tokens.** Rejeitada porque o tema escuro e a marca exigiriam sobrescrever centenas de valores.
- **Tokens gerados de arquivo JSON (Style Dictionary).** Adiada porque adiciona ferramenta Node ao build.
  Pode ser reavaliada na Fase 4.

## Consequências

Definida na change `add-gja-foundation-design-tokens` e seguintes. Todo widget declara na spec
os tokens de componente que usa.
