# ADR 0001 — Baseline de SDK Flutter/Dart

- **Status:** Aceita para o protótipo (revisar antes de qualquer adoção pelo portal)
- **Data:** 2026-10-24 (aceita em 2026-10-25)

## Contexto

As restrições de SDK do framework precisam ser compatíveis com o portal existente
(spec `gja/framework-architecture`, requisito "Compatibilidade com o SDK das aplicações consumidoras").
O portal não está neste repositório e não foi localizado na máquina de desenvolvimento.
Uma busca por `pubspec.yaml` em `D:\` e no perfil do usuário encontrou apenas projetos de curso.

Em 2026-10-25, o responsável definiu que o repositório é um **protótipo** e que a versão local
do SDK deve ser usada como baseline, sem aguardar o levantamento do portal.

## Levantamento

| Item | Valor | Origem |
|---|---|---|
| Flutter | 3.32.6 (stable, 2025-07-08) | `flutter --version` na máquina de desenvolvimento |
| Dart | 3.8.1 | `flutter --version` na máquina de desenvolvimento |
| Plataformas-alvo | web e Windows | decisão do responsável (protótipo) |
| Dependências de UI | nenhuma além do SDK Flutter | `pubspec.yaml` dos pacotes |
| Versões do portal | não verificadas | portal indisponível; fora do escopo do protótipo |

## Decisão

- `environment.sdk: ^3.8.0`
- `environment.flutter: ">=3.32.0"`
- Plataformas da galeria e da verificação de compatibilidade: web e Windows.

## Verificação de compatibilidade (tarefa 6.1)

Em 2026-10-25, um app descartável (`flutter create --platforms=web,windows`) foi criado fora do
repositório, em `%TEMP%\gja_compat_check`. Ele usou as mesmas restrições de SDK e dependeu de
`gja_ui` por `path:`. Depois da verificação, o app foi removido.

| Etapa | Resultado |
|---|---|
| `flutter pub get` | OK |
| `flutter build web` | OK |
| `flutter build windows` | OK (apenas o aviso MSB8029 por compilar sob `%TEMP%`) |

Achado: os pacotes internos declaram dependências entre si por versão (`gja_core: ^0.0.1`),
resolvidas pelo workspace. Um consumidor externo que use `path:` precisa de `dependency_overrides`
com `path:` para `gja_foundation`, `gja_core` e `gja_widgets`. Com distribuição por git
(ADR 0003), o consumidor declara cada pacote por `git:` + `path:` + `ref:`.

## Pendências antes de adoção pelo portal

1. Ler, sem alterar, `pubspec.yaml`, `pubspec.lock` e a configuração de pipeline do portal.
2. Se o portal usar versão menor que esta baseline, reduzir as restrições e reavaliar a ADR 0002.
3. Repetir a verificação de compatibilidade com as restrições e as plataformas reais do portal.

## Consequências

O protótipo segue com a baseline local. Nenhuma versão do framework deve ser adotada pelo portal
antes de concluir as pendências acima.
