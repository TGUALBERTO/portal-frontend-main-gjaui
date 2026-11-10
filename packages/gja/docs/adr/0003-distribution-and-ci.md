# ADR 0003 — Distribuição e integração contínua

- **Status:** Aceita para o protótipo
- **Data:** 2026-10-24 (aceita em 2026-10-25)
- **Responsável pela decisão:** responsável pelo protótipo; reavaliar com a liderança técnica antes da adoção em produção

## Contexto

Questões em aberto 2 e 6 do `design.md` da change `propose-gja-ui-framework`.
O repositório é um protótipo (ver ADR 0001) e ainda não tem remoto configurado.

## Decisão

| Questão | Decisão |
|---|---|
| Canal de distribuição dos pacotes | Repositório git privado com tags `gja_ui-vX.Y.Z`. Consumidores declaram cada pacote com `git:` (`url`, `path`, `ref`). |
| Plataforma de integração contínua | GitHub Actions (`.github/workflows/ci.yml`), que chama `tool/ci.sh` em todo pull request e em push para `main`. |

## Alternativas consideradas

- **Servidor pub privado:** exige infraestrutura nova. Reavaliar quando houver mais de duas aplicações consumidoras.
- **Azure DevOps / GitLab CI:** viáveis, porque o pipeline é só `tool/ci.sh`. Se o remoto da empresa
  for um deles, basta um arquivo de pipeline equivalente que chame o mesmo script.

## Consequências

- O pipeline de qualidade continua independente de plataforma (`tool/ci.sh` e `tool/ci.ps1`).
- O workflow fixa Flutter 3.32.6 (ADR 0001) e OpenSpec CLI 1.14.3.
- **Ainda não verificado em PR real:** o repositório não tem remoto. A primeira execução no GitHub
  deve ser acompanhada, e esta ADR deve ser atualizada com o resultado.
