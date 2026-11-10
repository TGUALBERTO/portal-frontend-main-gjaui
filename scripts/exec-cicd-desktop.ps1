#Requires -Version 7.0
<#
.SYNOPSIS
    Build de release desktop (Windows) do Portal GJA e publicacao na pasta de rede.

.DESCRIPTION
    Executa o ciclo completo de release:
        1. flutter clean
        2. flutter pub get
        3. flutter build windows --release
        4. copia a pasta Release para a rede com o nome "Release dd.MM.yyyy"
        5. verifica a copia e remove a ultima versao anterior do destino

    Se ja existir uma pasta com a data de hoje no destino, o nome ganha a hora
    ("Release 03.08.2026 14h32"). A ultima versao anterior so e removida
    depois que a nova publicacao for verificada com sucesso.

    O build local NAO e apagado (use -Move para mover em vez de copiar).

.PARAMETER ProjectRoot
    Raiz do projeto Flutter. Padrao: a pasta pai deste script (portal-frontend).

.PARAMETER Destination
    Pasta de rede onde o release e publicado.
    Padrao: Y:\AMS\AMS APLICAÇÕES\Portal GJA\Portal GJA Desktop

.PARAMETER SkipClean
    Pula o 'flutter clean' (build incremental, bem mais rapido).

.PARAMETER SkipBuild
    Nao builda nada: apenas publica os artefatos ja existentes em build\.
    Util para testar a parte de nomenclatura/copia em segundos.

.PARAMETER Move
    Move em vez de copiar (a pasta Release local deixa de existir).

.PARAMETER Open
    Abre o Explorer na pasta publicada ao final.

.EXAMPLE
    flutter execCICDDesktop

.EXAMPLE
    flutter execCICDDesktop -SkipClean -Open

.EXAMPLE
    flutter execCICDDesktop -SkipBuild -Destination 'D:\temp'
#>
[CmdletBinding()]
param(
    [string] $ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string] $Destination = 'Y:\AMS\AMS APLICAÇÕES\Portal GJA\Portal GJA Desktop',
    [switch] $SkipClean,
    [switch] $SkipBuild,
    [switch] $Move,
    [switch] $Open
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# robocopy usa exit codes 0-7 para sucesso; sem isso o PS 7.4+ trataria como erro.
$PSNativeCommandUseErrorActionPreference = $false

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

function Write-Step {
    param([string] $Message)
    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Info {
    param([string] $Message)
    Write-Host "    $Message" -ForegroundColor DarkGray
}

function Write-Ok {
    param([string] $Message)
    Write-Host "    OK  $Message" -ForegroundColor Green
}

function Resolve-FlutterExe {
    foreach ($name in @('flutter.bat', 'flutter')) {
        $cmd = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue |
               Select-Object -First 1
        if ($cmd) { return $cmd.Source }
    }
    throw 'flutter nao encontrado no PATH. Verifique a instalacao do Flutter SDK.'
}

function Invoke-Flutter {
    param([Parameter(Mandatory)][string[]] $Arguments)

    Write-Info "> flutter $($Arguments -join ' ')"
    & $script:FlutterExe @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "'flutter $($Arguments -join ' ')' falhou (exit code $LASTEXITCODE)."
    }
}

function Get-FolderStats {
    param([Parameter(Mandatory)][string] $Path)

    $measured = Get-ChildItem -LiteralPath $Path -Recurse -File |
                Measure-Object -Property Length -Sum
    return [pscustomobject]@{
        Count = [int] $measured.Count
        Bytes = [long] ($measured.Sum ?? 0)
    }
}

try {
    # ------------------------------------------------------------------ 1. Ambiente
    Write-Step 'Validando ambiente'

    if (-not (Test-Path -LiteralPath $ProjectRoot)) {
        throw "Projeto nao encontrado: $ProjectRoot"
    }
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

    if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot 'pubspec.yaml'))) {
        throw "'$ProjectRoot' nao e um projeto Flutter (pubspec.yaml nao encontrado)."
    }
    Write-Ok "Projeto: $ProjectRoot"

    $script:FlutterExe = Resolve-FlutterExe
    Write-Ok "Flutter: $script:FlutterExe"

    if (-not (Test-Path -LiteralPath $Destination)) {
        throw "Destino inacessivel: '$Destination'. A unidade de rede esta mapeada e online?"
    }
    $Destination = (Resolve-Path -LiteralPath $Destination).Path
    Write-Ok "Destino: $Destination"

    # ------------------------------------------------------------------ 2. Build
    if ($SkipBuild) {
        Write-Step 'Build ignorado (-SkipBuild) - publicando artefatos existentes'
    }
    else {
        Push-Location -LiteralPath $ProjectRoot
        try {
            if ($SkipClean) {
                Write-Step 'flutter clean ignorado (-SkipClean)'
            }
            else {
                Write-Step 'flutter clean'
                Invoke-Flutter @('clean')
            }

            Write-Step 'flutter pub get'
            Invoke-Flutter @('pub', 'get')

            Write-Step 'flutter build windows --release'
            Invoke-Flutter @('build', 'windows', '--release')
        }
        finally {
            Pop-Location
        }
    }

    # ------------------------------------------------------------------ 3. Artefatos
    Write-Step 'Localizando artefatos do build'

    $candidates = @(
        (Join-Path $ProjectRoot 'build\windows\x64\runner\Release')   # Flutter atual
        (Join-Path $ProjectRoot 'build\windows\runner\Release')       # layout antigo
    )
    $releaseDir = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $releaseDir) {
        throw "Pasta Release nao encontrada. Procurei em:`n      - $($candidates -join "`n      - ")"
    }

    $exe = Get-ChildItem -LiteralPath $releaseDir -Filter '*.exe' -File | Select-Object -First 1
    if (-not $exe) {
        throw "Nenhum .exe em '$releaseDir' - o build nao produziu o executavel."
    }

    $sourceStats = Get-FolderStats -Path $releaseDir
    Write-Ok "$releaseDir"
    Write-Ok ("{0} | {1} arquivos | {2:N1} MB" -f $exe.Name, $sourceStats.Count, ($sourceStats.Bytes / 1MB))

    # ------------------------------------------------------------------ 4. Nome do destino
    # Apenas pastas de release criadas por este script; ignora links/juncoes.
    $previousRelease = Get-ChildItem -LiteralPath $Destination -Directory |
        Where-Object {
            $_.Name -match '^Release \d{2}\.\d{2}\.\d{4}( \d{2}h\d{2}( \(\d+\))?)?$' -and
            -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    $now = Get-Date
    $baseName   = 'Release ' + $now.ToString('dd.MM.yyyy')
    $targetName = $baseName

    if (Test-Path -LiteralPath (Join-Path $Destination $targetName)) {
        $timePart   = $now.ToString('HH\hmm')
        $targetName = "$baseName $timePart"
        $counter    = 2
        while (Test-Path -LiteralPath (Join-Path $Destination $targetName)) {
            $targetName = "$baseName $timePart ($counter)"
            $counter++
        }
        Write-Info "'$baseName' ja existe no destino - publicando como '$targetName'"
    }

    $targetPath = Join-Path $Destination $targetName

    # ------------------------------------------------------------------ 5. Publicacao
    $verb = if ($Move) { 'Movendo' } else { 'Copiando' }
    Write-Step "$verb para: $targetPath"

    $roboArgs = @(
        $releaseDir
        $targetPath
        '/E'            # subpastas, inclusive vazias
        '/R:2'          # 2 tentativas por arquivo
        '/W:5'          # 5s entre tentativas
        '/NFL' , '/NDL' # sem listar arquivos/pastas
        '/NJH' , '/NJS' # sem cabecalho/rodape
        '/NP'           # sem percentual
    )
    if ($Move) { $roboArgs += '/MOVE' }

    & robocopy.exe @roboArgs
    $roboCode = $LASTEXITCODE
    $global:LASTEXITCODE = 0    # robocopy usa 0-7 como sucesso; nao poluir o prompt

    if ($roboCode -ge 8) {
        throw "robocopy falhou (exit code $roboCode) ao publicar em '$targetPath'."
    }

    # ------------------------------------------------------------------ 6. Verificacao
    Write-Step 'Verificando integridade da copia'

    if (-not (Test-Path -LiteralPath $targetPath)) {
        throw "Pasta de destino nao foi criada: $targetPath"
    }
    $targetStats = Get-FolderStats -Path $targetPath

    if ($targetStats.Count -ne $sourceStats.Count -or $targetStats.Bytes -ne $sourceStats.Bytes) {
        throw ("Copia incompleta: origem {0} arquivos / {1} bytes, destino {2} arquivos / {3} bytes." -f
               $sourceStats.Count, $sourceStats.Bytes, $targetStats.Count, $targetStats.Bytes)
    }
    if (-not (Test-Path -LiteralPath (Join-Path $targetPath $exe.Name))) {
        throw "Executavel '$($exe.Name)' nao chegou ao destino."
    }
    Write-Ok ("{0} arquivos | {1:N1} MB conferidos" -f $targetStats.Count, ($targetStats.Bytes / 1MB))

    # ------------------------------------------------------------------ 7. Remocao da ultima versao anterior
    if ($previousRelease) {
        $previousPath = (Resolve-Path -LiteralPath $previousRelease.FullName).Path
        $destinationPath = (Resolve-Path -LiteralPath $Destination).Path.TrimEnd('\', '/')
        $previousParent = (Split-Path -Parent $previousPath).TrimEnd('\', '/')
        if ($previousParent -ne $destinationPath -or $previousPath -eq $targetPath) {
            throw "Remocao cancelada: a versao anterior nao e uma pasta direta do destino: '$previousPath'."
        }
        Write-Step "Removendo ultima versao anterior: $previousPath"
        Remove-Item -LiteralPath $previousPath -Recurse -Force
        Write-Ok 'Ultima versao anterior removida'
    }

    # ------------------------------------------------------------------ 8. Resumo
    $stopwatch.Stop()
    Write-Host ''
    Write-Host 'RELEASE PUBLICADO' -ForegroundColor Green
    Write-Host "    Pasta      : $targetPath"
    Write-Host "    Executavel : $($exe.Name)"
    Write-Host "    Tamanho    : $('{0:N1} MB' -f ($targetStats.Bytes / 1MB))"
    Write-Host "    Build local: $(if ($Move) { 'movido (removido)' } else { $releaseDir })"
    Write-Host "    Duracao    : $('{0:mm\:ss}' -f $stopwatch.Elapsed)"
    Write-Host ''

    if ($Open) { Invoke-Item -LiteralPath $targetPath }
}
catch {
    $stopwatch.Stop()
    Write-Host ''
    Write-Host 'FALHA NO RELEASE' -ForegroundColor Red
    Write-Host "    $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "    Duracao: $('{0:mm\:ss}' -f $stopwatch.Elapsed)" -ForegroundColor DarkGray
    Write-Host ''
    exit 1
}
