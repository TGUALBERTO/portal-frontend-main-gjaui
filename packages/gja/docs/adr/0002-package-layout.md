# ADR 0002 — Workspace com pacotes por camada

- **Status:** Aceita (sujeita à confirmação da ADR 0001)
- **Data:** 2026-10-24

## Contexto

A spec `gja/framework-architecture` exige camadas publicadas como unidades independentes,
dependência em uma só direção e ausência de ciclos. Pub workspaces exigem **Dart ≥ 3.6**.
A baseline provisória (ADR 0001) é Dart 3.8.1.

## Decisão

Usar um pub workspace na raiz do repositório com os membros:

| Membro | Papel | Depende de |
|---|---|---|
| `packages/gja_foundation` | tokens, tema, breakpoints, densidade | Flutter SDK |
| `packages/gja_core` | interação, overlay, localização, validação, dados | `gja_foundation` |
| `packages/gja_widgets` | widgets públicos | `gja_foundation`, `gja_core` |
| `packages/gja_ui` | agregador (só reexporta) | as três camadas |
| `apps/gja_gallery` | galeria de demonstração | `gja_ui` |
| `tool/gja_checks` | verificações de conformidade (CLI Dart) | `analyzer`, `path`, `yaml` |

A direção das dependências é garantida pelos `pubspec.yaml`, e `gja_checks architecture`
verifica os imports dentro de cada pacote.

## Alternativas consideradas

- **Dependências `path:` sem workspace.** Fica como alternativa caso o portal use Dart < 3.6.
  A estrutura de pastas é a mesma, removendo `resolution: workspace` e a seção `workspace:` da raiz.
- **Pacote único com pastas.** Os limites dependeriam apenas de lint.
- **Um pacote por widget.** Custo de versionamento desproporcional para cerca de 60 itens.
- **Melos.** Ferramenta externa desnecessária com pub workspaces.

## Consequências

Um único `pubspec.lock` e uma única resolução de dependências para todo o repositório.
Consumidores dependem de `gja_ui`, ou só de `gja_foundation` quando precisarem apenas dos tokens.

Os nomes atuais dos pacotes seguem a ADR 0010.
