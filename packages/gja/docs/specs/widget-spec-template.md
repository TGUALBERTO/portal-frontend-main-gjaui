<!--
Template de spec de widget do framework GJA.

Como usar:
1. Crie a change: `openspec new change add-gja-<widget>` (kebab-case, igual ao id da spec).
2. Copie este arquivo, a partir da linha "# Spec Delta", para
   `openspec/changes/add-gja-<widget>/specs/gja/widgets/gja-<widget>/spec.md`.
3. Substitua tudo entre <...>. Mantenha as etiquetas [..] exatamente como estão:
   `gja_checks specs` exige ao menos um requisito com cada uma.
4. Repita um bloco "### Requirement:" quando houver mais de um comportamento. Cada requisito
   descreve um único comportamento, em até 500 caracteres antes do primeiro cenário,
   e tem ao menos um cenário.
5. Uma seção que não se aplica continua presente, como decisão verificável
   (por exemplo, "SHALL NOT exibir estado hover").
6. Os cenários são os critérios de aceitação. Cada um vira um teste nomeado
   "<requisito> — <cenário>" (spec gja/spec-governance, "Rastreabilidade entre cenários e testes").
7. Valide com: `openspec validate add-gja-<widget> --strict` e `dart run gja_checks specs`.

Mapeamento das 12 seções obrigatórias:
  1 Objetivo e escopo ...... ## Purpose
  2 API pública ............ [API]
  3 Comportamento .......... [Comportamento]
  4 Aparência .............. [Aparência]
  5 Estados ................ [Estados]
  6 Acessibilidade ......... [Acessibilidade]
  7 Responsividade ......... [Responsividade]
  8 Integração ............. [Integração]
  9 Critérios de aceitação . os #### Scenario de todos os requisitos
 10 Testes ................. [Testes]
 11 Documentação ........... [Documentação]
 12 Restrições ............. [Restrições]
-->
# Spec Delta

## Purpose

<Problema que o GjaX resolve e responsabilidades do componente, em 1 ou 2 frases com 50 caracteres ou mais.>

## ADDED Requirements

### Requirement: [API] Propriedades
`GjaX` SHALL expor as propriedades:

| Prop | Tipo | Padrão |
|---|---|---|
| `<prop>` | `<Tipo>` | `<padrão>` ou obrigatória |

#### Scenario: Uso mínimo
- **GIVEN** uma árvore com `GjaApp`
- **WHEN** `GjaX` é criado apenas com as propriedades obrigatórias
- **THEN** <resultado observável com os valores padrão>

### Requirement: [API] Callbacks e controlador
`GjaX` SHALL notificar `<onEvento>` (o nome do evento do SAPUI5, como `onPress` ou `onSelect`) quando <evento>. Com `enabled` `false`, o componente MUST ficar desabilitado; um callback nulo significa só que não há ação.

#### Scenario: Componente desabilitado
- **GIVEN** `GjaX` com `enabled: false` e um `<onEvento>`
- **WHEN** o usuário tenta interagir por toque, clique ou teclado
- **THEN** `<onEvento>` não é chamado e a semântica informa desabilitado

### Requirement: [Comportamento] <interação, transição, validação ou erro>
`GjaX` SHALL <comportamento único e observável>.

#### Scenario: <caso principal>
- **GIVEN** <estado inicial>
- **WHEN** <ação>
- **THEN** <resultado>

### Requirement: [Aparência] Tokens de componente
`GjaX` SHALL obter aparência somente dos tokens `<grupo>.<token>` do tema ativo (cores, tipografia, espaçamento, raio, elevação, dimensões), sem valores literais.

#### Scenario: Troca de tema
- **GIVEN** `GjaX` renderizado no tema claro
- **WHEN** o tema ativo muda para escuro
- **THEN** o componente usa os tokens do tema escuro sem ser recriado com outros parâmetros

### Requirement: [Estados] Estados visuais
`GjaX` SHALL apresentar os estados <normal, hover, foco, pressionado, desabilitado, carregando, erro, selecionado> conforme `gja/foundation/interaction-states`, e SHALL NOT apresentar <estados não aplicáveis>.

#### Scenario: Foco por teclado
- **GIVEN** `GjaX` habilitado
- **WHEN** recebe foco pela tecla Tab
- **THEN** exibe o indicador de foco definido pelos fundamentos

### Requirement: [Acessibilidade] Teclado e foco
`GjaX` SHALL ser operável por teclado: <teclas e efeitos>. A ordem de foco MUST seguir a ordem visual.

#### Scenario: Ativação por teclado
- **GIVEN** `GjaX` focado
- **WHEN** o usuário pressiona <Enter/Espaço/setas>
- **THEN** <efeito equivalente à interação por ponteiro>

### Requirement: [Acessibilidade] Semântica e contraste
`GjaX` SHALL expor ao leitor de tela rótulo, papel, estado (<habilitado, selecionado, marcado, expandido…>) e valor, quando houver, com contraste, escala de texto e área de toque conforme `gja/foundation/accessibility`. Ícones decorativos MUST ficar fora da árvore semântica.

#### Scenario: Leitor de tela
- **WHEN** um leitor de tela percorre `GjaX`
- **THEN** anuncia <rótulo, papel, estado e valor>

### Requirement: [Responsividade] Tamanhos de tela e densidade
`GjaX` SHALL <comportamento por breakpoint, densidade e plataforma (web, desktop, mobile)>.

#### Scenario: Densidade compacta
- **GIVEN** uma subárvore com densidade `compact`
- **WHEN** `GjaX` é renderizado nela
- **THEN** usa as dimensões compactas dos tokens

### Requirement: [Integração] Dependências
`GjaX` SHALL depender somente de: `gja/foundation/<...>`, `gja/core/<...>`, `gja/widgets/<...>`. Requisitos dessas specs são referenciados, não copiados.

#### Scenario: Funciona sem Material
- **GIVEN** uma árvore criada apenas com `GjaApp`
- **WHEN** `GjaX` é renderizado
- **THEN** não ocorrem exceções relacionadas a ancestrais Material ou Cupertino

### Requirement: [Testes] Cobertura exigida
`GjaX` MUST ter um teste de widget por cenário, goldens dos estados (claro/escuro × densidades) e a bateria mínima de acessibilidade de `gja/foundation/accessibility`: `textContrastGuideline`, `labeledTapTargetGuideline`, `MinimumTapTargetGuideline` com o alvo de cada densidade, render com `textScaler` 2,0 sem estouro, `matchesSemantics` e teclado.

#### Scenario: Rastreabilidade
- **WHEN** a revisão compara os cenários desta spec com a suíte de testes
- **THEN** cada cenário tem um teste nomeado "<requisito> — <cenário>"

### Requirement: [Documentação] Exemplos mínimos
`GjaX` SHALL ter dartdoc em toda API pública e uma página na galeria com <exemplos mínimos e casos de uso recomendados>.

#### Scenario: Página na galeria
- **WHEN** a change é concluída
- **THEN** a galeria exibe `GjaX` em <estados e variantes documentados>

### Requirement: [Restrições] Fora do escopo
`GjaX` SHALL NOT <comportamentos fora do escopo e decisões arquiteturais que não podem ser violadas>.

#### Scenario: <restrição verificável>
- **WHEN** <tentativa de uso fora do escopo>
- **THEN** <resultado esperado, por exemplo erro de compilação ou assert documentado>
