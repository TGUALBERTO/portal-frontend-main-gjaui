#!/usr/bin/env bash
# Pipeline de qualidade do framework GJA. Executa a partir de qualquer
# diretório; termina com código diferente de 0 na primeira etapa que falhar.
# Requer: Flutter (ADR 0001) e OpenSpec CLI 1.14.3 (npm i -g @fission-ai/openspec@1.14.3).
set -euo pipefail

cd "$(dirname "$0")/.."

step() { printf '\n==> %s\n' "$1"; }

step "Dependências"
flutter pub get

step "Análise estática"
dart analyze . --fatal-infos

step "Testes Flutter"
for dir in packages/* apps/*; do
  if [ -d "$dir/test" ]; then
    # Goldens têm referência gerada no Windows (ADR 0008): excluídos no Linux.
    (cd "$dir" && flutter test --exclude-tags golden)
  fi
done

step "Testes de gja_checks"
(cd tool/gja_checks && dart test)

step "Validação OpenSpec"
openspec validate --all --strict --no-interactive

step "Verificações de conformidade"
dart run gja_checks all

printf '\nPipeline concluído sem falhas.\n'
