# Registros de decisão arquitetural (ADR)

Um arquivo por decisão, numerado em sequência (`NNNN-titulo-em-kebab-case.md`).
Cada ADR tem: **Status**, **Data**, **Contexto**, **Decisão**, **Alternativas consideradas** e **Consequências**.

| ADR | Título | Status |
|---|---|---|
| [0001](0001-sdk-baseline.md) | Baseline de SDK Flutter/Dart | Aceita (protótipo) |
| [0002](0002-package-layout.md) | Workspace com pacotes por camada | Aceita |
| [0003](0003-distribution-and-ci.md) | Distribuição e integração contínua | Aceita (protótipo) |
| [0004](0004-no-material-public-api.md) | API pública sem Material/Cupertino | Aceita |
| [0005](0005-design-tokens-three-levels.md) | Design tokens em três níveis | Aceita |
| [0006](0006-state-and-data-integration.md) | Estado controlado e integração com dados por contrato | Aceita |
| [0007](0007-one-change-per-widget.md) | Uma change OpenSpec por widget | Aceita |
| [0008](0008-golden-reference-windows.md) | Goldens com referência no Windows | Aceita (protótipo) |
| [0009](0009-provisional-horizon-values.md) | Valores provisórios do tema Horizon | Aceita (protótipo) |
| [0010](0010-rename-to-gja.md) | Framework renomeado de Rebic para GJA | Aceita |

Exceções de import de `material`/`cupertino` em código de biblioteca exigem uma ADR aceita
e o marcador `// gja-adr: NNNN` na linha do import (ver ADR 0004).
