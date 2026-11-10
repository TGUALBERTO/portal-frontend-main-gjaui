# ADR 0010 — Framework renomeado de Rebic para GJA

- **Status:** Aceita
- **Data:** 2026-11-09

## Contexto

O framework nasceu com o nome provisório Rebic. O primeiro consumidor é o portal GJA, e o tema passa a ser
identificado com o nome do grupo.

## Decisão

Renomear o framework inteiro de Rebic para GJA:

| Antes | Depois |
|---|---|
| `rebic_foundation`, `rebic_core`, `rebic_widgets`, `rebic_ui` | `gja_foundation`, `gja_core`, `gja_widgets`, `gja_ui` |
| `apps/rebic_gallery`, `tool/rebic_checks` | `apps/gja_gallery`, `tool/gja_checks` |
| Prefixo de tipos `Rebic` (`RebicApp`, `RebicIcons`…) | `Gja` (`GjaApp`, `GjaIcons`…) |
| Specs `rebic/...` | `gja/...` |
| Marcador `// rebic-adr: NNNN` | `// gja-adr: NNNN` |

O prefixo dos tipos segue o Effective Dart: siglas com mais de duas letras são capitalizadas como palavras (`Gja`).
O nome em texto corrido é `GJA`.

As changes arquivadas do OpenSpec e os CHANGELOGs também foram renomeados, para que os IDs de spec e os caminhos
continuem válidos; o histórico do git preserva os nomes anteriores.

## Alternativas consideradas

- **Renomear só o agregador (`gja_ui`).** Primeiro passo adotado, mas deixava dois nomes convivendo na API pública.
- **Prefixo `GJA` em maiúsculas nos tipos.** Fora do Effective Dart e ilegível em nomes compostos (`GJAIconTabBar`).

## Consequências

Consumidores trocam dependências e imports para `gja_*` e os tipos `Rebic*` para `Gja*`; não há aliases de
compatibilidade, pois o framework ainda é protótipo (ADR 0001). As tags de distribuição passam a ser
`gja_ui-vX.Y.Z` (ADR 0003).
