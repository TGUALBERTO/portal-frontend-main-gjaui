# gja_checks

Verificações de conformidade do framework GJA, executadas localmente e na integração contínua (`tool/ci`).
Elas implementam as regras automatizáveis das specs `gja/framework-architecture` e `gja/spec-governance`.

## Uso

Na raiz do repositório:

```sh
dart run gja_checks all            # todas as verificações
dart run gja_checks architecture   # uma verificação
dart run gja_checks specs --root <outro-repositório>
```

Sem `--root`, a raiz é procurada subindo a partir do diretório atual: é o primeiro diretório com `openspec/` e `pubspec.yaml`.

| Código de saída | Significado |
|---|---|
| 0 | nenhuma violação |
| 1 | há violações (listadas como `[verificação] arquivo:linha: mensagem`) |
| 64 | uso incorreto ou raiz não encontrada |

## Verificações

### `architecture`

- **Camadas:** `gja_foundation` ← `gja_core` ← `gja_widgets` ← `gja_ui`.
  Um import ou export de camada posterior em `packages/*/lib` é violação.
- **Material/Cupertino:** reexportar é sempre violação. Importar exige o marcador `// gja-adr: NNNN`
  na mesma linha, apontando para um arquivo `docs/adr/NNNN-*.md` existente (ADR 0004).
- **Primitivos de tokens:** em `packages/*/lib` de qualquer pacote diferente de `gja_foundation`, um import
  ou export de `package:gja_foundation/gja_primitives.dart` ou de `package:gja_foundation/src/…` é violação.
  Isso inclui o agregador `gja_ui`, que não pode reexportar os primitivos (ADR 0005 e spec
  `gja/foundation/design-tokens`). Os testes (`test/`) e as aplicações podem importar os primitivos.
- **Ciclos entre módulos internos:** um módulo é `lib/src/<categoria>/<widget>` em `gja_widgets`
  e `lib/src/<pasta>` nos demais pacotes. As bibliotecas públicas (`lib/*.dart`) não entram no grafo.
- **API pública:** resolve com o analisador do Dart cada biblioteca `packages/*/lib/*.dart` e inspeciona
  os símbolos do namespace exportado. São verificados supertipos, mixins, interfaces, construtores, métodos,
  campos, getters/setters, typedefs, extensões e limites de tipos genéricos, inclusive dentro de argumentos
  de tipo, funções e records. Qualquer tipo definido em `material` ou `cupertino` é violação.
  Esta é a etapa mais lenta: alguns segundos, porque resolve o Flutter.

### `tokens`

Procura valores visuais literais em `packages/gja_widgets/lib` (ADR 0005):

- cores (`Color(...)`, `Colors.`);
- `EdgeInsets`, `BorderRadius`/`Radius` e `Duration` com números;
- `TextStyle` com `fontSize`/`height`/`letterSpacing`;
- argumentos de dimensão (`width:`, `height:`, `size:`, `elevation:` …) com números diferentes de zero.

Comentários são ignorados. As exceções ficam em [`token_exceptions.yaml`](token_exceptions.yaml), e cada uma
exige `file`, `contains` (trecho da linha) e `reason` não vazio.

### `specs`

Analisa as specs de componente (`gja/widgets/*`, `gja/foundation/*`, `gja/core/*`) em `openspec/specs`
e nas changes ativas (fora de `archive`):

- **Estrutura (widgets):** `## Purpose` e ao menos um requisito com cada etiqueta
  `[API]`, `[Comportamento]`, `[Aparência]`, `[Estados]`, `[Acessibilidade]`, `[Responsividade]`,
  `[Integração]`, `[Testes]`, `[Documentação]` e `[Restrições]`.
  Deltas de widget já existente (MODIFIED etc.) não precisam repetir a estrutura.
- **Referências:** todo `gja/(widgets|foundation|core)/<id>` citado deve existir em `openspec/specs`
  ou, para specs de change, na mesma change.
- **Ciclos:** para widgets, as dependências são as referências dentro dos requisitos `[Integração]`;
  para fundamentos e núcleo, todas as referências. O grafo efetivo (specs principais + changes ativas)
  deve ser acíclico.

As specs `gja/framework-architecture` e `gja/spec-governance` não são verificadas aqui, porque citam
caminhos apenas como exemplo.

### `catalog`

Valida [`docs/catalog.yaml`](../../docs/catalog.yaml):

- formato e unicidade dos ids;
- dependências conhecidas e grafo acíclico;
- prioridade e fase de um item nunca mais urgentes que as de suas dependências;
- `specified`/`implemented`/`deprecated` exigem spec (principal ou em change ativa), e `planned` não pode ter spec principal;
- toda spec principal de componente está no catálogo;
- as dependências do catálogo aparecem na spec;
- widget `implemented` tem a pasta `packages/gja_widgets/lib/src/<categoria>/<widget>`.

## Testes

```sh
cd tool/gja_checks && dart test
```

As fixtures são geradas em diretórios temporários pelos próprios testes. As do analisador usam
`tool/gja_checks/.test_tmp/`, que fica dentro do workspace para resolver `package:flutter`
e é ignorado pelo git e pelo `dart analyze`.
