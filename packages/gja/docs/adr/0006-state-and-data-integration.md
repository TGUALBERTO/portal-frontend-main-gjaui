# ADR 0006 — Estado controlado e integração com dados por contrato

- **Status:** Aceita
- **Data:** 2026-10-24

## Contexto

O framework precisa ser consumido por aplicações com arquiteturas de estado diferentes e integrado
a sistemas corporativos sem acoplamento a backends específicos.

## Decisão

1. **Estado:** os componentes com valor são controlados: recebem o valor e avisam a mudança por callback, com os
   nomes da propriedade e do evento do SAPUI5 (`selected` + `onSelect`, `value` + `onChange`), conforme a regra de
   nomes de `gja/framework-architecture`.
   Os componentes complexos (Table, DataGrid, Tree, Tabs, Form) oferecem um controlador público opcional
   baseado em `ChangeNotifier`. Nenhuma biblioteca de gerenciamento de estado é exigida.
2. **Dados:** `gja_core` define o contrato `GjaDataSource<T>`:
   - busca paginada com ordenação, filtros e termo de busca;
   - total opcional e cancelamento;
   - estados `loading`/`empty`/`error`.

   O padrão é paginação no servidor. Uma implementação em memória fica disponível para testes e listas pequenas.
3. **Adaptadores** (REST, OData) ficam em pacote opcional na Fase 4, fora do núcleo.

## Alternativas consideradas

- **Data binding por strings (estilo modelos do SAPUI5).** Rejeitada porque perde a tipagem do Dart.
- **Adotar Riverpod/Bloc no framework.** Rejeitada porque impõe a arquitetura às aplicações consumidoras.

## Consequências

O contrato será especificado em `gja/core/data-source` (change `add-gja-core-data-source`, Fase 3).
