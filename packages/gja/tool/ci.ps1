# Pipeline de qualidade do framework GJA (Windows PowerShell 5.1+).
# Equivalente a tool/ci.sh; termina com código diferente de 0 na primeira etapa que falhar.
# Requer: Flutter (ADR 0001) e OpenSpec CLI 1.14.3 (npm i -g @fission-ai/openspec@1.14.3).
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Invoke-Step([string]$Name, [scriptblock]$Command) {
    Write-Host "`n==> $Name"
    & $Command
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Falha na etapa: $Name"
        exit $LASTEXITCODE
    }
}

Invoke-Step 'Dependências' { flutter pub get }
Invoke-Step 'Análise estática' { dart analyze . --fatal-infos }

foreach ($dir in @(Get-ChildItem -Directory packages, apps)) {
    if (Test-Path (Join-Path $dir.FullName 'test')) {
        Invoke-Step "Testes Flutter: $($dir.Name)" {
            Push-Location $dir.FullName
            try { flutter test } finally { Pop-Location }
        }
    }
}

Invoke-Step 'Testes de gja_checks' {
    Push-Location tool/gja_checks
    try { dart test } finally { Pop-Location }
}
Invoke-Step 'Validação OpenSpec' { openspec validate --all --strict --no-interactive }
Invoke-Step 'Verificações de conformidade' { dart run gja_checks all }

Write-Host "`nPipeline concluído sem falhas."
