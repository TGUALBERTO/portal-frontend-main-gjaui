# ADR 0007 — Uma change OpenSpec por widget

- **Status:** Aceita
- **Data:** 2026-10-24

## Contexto

A spec `gja/spec-governance` exige uma spec por widget. O OpenSpec 1.14.3 aceita várias specs por change,
mas descarta no archive seções `##` fora de `Purpose`/`Requirements`.

## Decisão

1. Cada widget tem a change `add-gja-<widget>`, que contém spec, design (quando necessário), tarefas,
   implementação, testes, página na galeria e atualização de `docs/catalog.yaml`.
2. **Exceção:** até três specs na mesma change para widgets inseparáveis
   (por exemplo, `GjaForm` + `GjaFormField`), com justificativa na proposta.
3. As 12 seções obrigatórias da spec de widget são requisitos etiquetados
   (`[API]`, `[Comportamento]`, …) conforme o `docs/specs/widget-spec-template.md`.
4. Fundamentos e infraestruturas do núcleo seguem a mesma regra
   (`add-gja-foundation-<x>`, `add-gja-core-<x>`).

## Alternativas consideradas

- **Escrever todas as specs antes de implementar.** Rejeitada porque as specs ficariam desatualizadas
  e o lote de revisão seria grande demais.
- **Uma change por fase.** Rejeitada porque a rastreabilidade e o archive deixariam de ser independentes.

## Consequências

São cerca de 75 changes ao longo das fases. O custo por change é reduzido pelo template,
pelas regras em `openspec/config.yaml` e por `gja_checks`.
