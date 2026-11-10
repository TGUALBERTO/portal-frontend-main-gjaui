# ADR 0008 — Goldens com referência no Windows (provisório)

- **Status:** Aceita (protótipo)
- **Data:** 2026-10-26

## Contexto

O template de widget exige goldens de cada widget com aparência própria (temas claro e escuro × densidades). O
rasterizador do Flutter produz pixels diferentes em cada sistema operacional, sobretudo no antialiasing do texto.
Uma referência gerada num sistema falha em outro.

O desenvolvimento do protótipo roda em Windows (`tool/ci.ps1`, SDK local, ADR 0001), e o pipeline do GitHub roda em
`ubuntu-latest` (`tool/ci.sh`, ADR 0003). Não há ambiente Linux disponível para gerar a referência.

## Decisão

1. Os goldens ficam ao lado dos testes, em `test/**/goldens/`, com a etiqueta `golden` declarada no
   `dart_test.yaml` do pacote.
2. A referência é gerada no Windows, com `flutter test --update-goldens --tags golden`.
3. `tool/ci.ps1` (Windows) executa todos os testes, incluindo os goldens.
4. `tool/ci.sh` (Linux) executa `flutter test --exclude-tags golden`.
5. Os goldens usam a fonte Inter real (`test/support/fonts.dart`), para mostrar a aparência de produção. Testes que
   medem pixels de texto, como a diretriz de contraste, usam a fonte de teste padrão, cujos glifos são sólidos.

## Alternativas consideradas

- **Referência Linux gerada num contêiner ou num job do GitHub.** É o destino desejado, mas exige um ambiente Linux
  que o protótipo não tem.
- **Pacote `alchemist`.** Ele gera goldens de CI com texto substituído por blocos, independentes do sistema. Foi
  adiado: acrescenta dependência e um segundo conjunto de imagens.
- **Tolerância de comparação maior.** Foi rejeitada porque esconderia regressões reais de cor e espaçamento.

## Consequências

- O pipeline do GitHub não verifica a aparência por imagem até existir a referência Linux. Estilo, cor e dimensões
  continuam verificados por valor nos testes de widget.
- Quem atualiza um widget visual roda os goldens no Windows antes do merge (checklist em `docs/CONTRIBUTING.md`).
- **Condição de saída:** gerar a referência no Linux (job dedicado ou `alchemist`), remover o `--exclude-tags golden`
  de `tool/ci.sh` e marcar este ADR como substituído.
