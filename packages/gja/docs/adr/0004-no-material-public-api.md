# ADR 0004 — API pública sem Material/Cupertino

- **Status:** Aceita
- **Data:** 2026-10-24

## Contexto

O framework tem identidade própria, e os widgets precisam funcionar sem `MaterialApp`, `Theme` ou `Material`
como ancestrais (spec `gja/framework-architecture`).

## Decisão

1. As bibliotecas dos pacotes do framework usam `package:flutter/widgets.dart` e, quando necessário,
   `rendering`, `services`, `semantics`, `gestures`, `animation`, `painting` e `foundation`.
2. Nenhum símbolo exportado pode referenciar tipos de `material` ou `cupertino` em supertipos, parâmetros,
   retornos, campos ou typedefs. Também é proibido reexportar essas bibliotecas.
3. Um import interno de `material`/`cupertino` só é permitido com uma ADR aceita específica para ele.
   A linha do import deve ter o marcador `// gja-adr: NNNN`, onde `NNNN` é o número dessa ADR em `docs/adr/`.
   A ADR deve justificar o uso, provar que ele não exige ancestrais Material e trazer um plano de remoção.
4. Testes podem importar Material, por exemplo para afirmar que ele está ausente.

`gja_checks architecture` aplica as regras 2 e 3.

## Alternativas consideradas

- **Construir sobre Material com tema customizado.** Rejeitada porque acopla a API e a aparência ao Material.
- **Proibição absoluta, sem exceções.** Rejeitada porque a seleção de texto pode precisar de reuso pontual
  (ver risco de `GjaTextField` no `design.md`).

## Consequências

Componentes como `GjaTextField` e os seletores de data exigirão mais implementação própria.
Uma possível exceção será decidida em uma ADR dentro da change do componente.
