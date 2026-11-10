#Requires -Version 7.0
<#
.SYNOPSIS
    Gera o keystore de release do app Android (Portal GJA) e o que o GitLab CI
    precisa para assinar o APK.

.DESCRIPTION
    O Android so instala uma atualizacao por cima do app se ela vier assinada com
    o MESMO certificado. Este script cria esse certificado UMA vez:

        1. gera uma senha aleatoria (32 caracteres alfanumericos)
        2. cria o keystore PKCS12 com uma chave RSA 2048 (keytool -genkeypair)
        3. grava o keystore em base64, numa linha so, para a variavel de CI
        4. opcionalmente escreve android\key.properties para builds locais
        5. mostra a senha, o SHA-256 do certificado e as variaveis a criar no GitLab

    O keystore fica FORA do repositorio (padrao: %USERPROFILE%\.gja-keys).

    ATENCAO: quem perde o keystore ou a senha nunca mais consegue atualizar o app
    ja instalado nos coletores (so desinstalando). Guarde os dois no cofre de
    senhas da empresa. Por isso o script NUNCA sobrescreve um keystore existente.

    A senha aparece uma unica vez, no fim da execucao. Ela nao e gravada em
    arquivo, a nao ser no android\key.properties quando -WriteKeyProperties e usado.

.PARAMETER OutDir
    Pasta onde o keystore e o base64 sao gravados. Padrao: %USERPROFILE%\.gja-keys

.PARAMETER Alias
    Alias da chave dentro do keystore. Padrao: gjamobile (o mesmo padrao do CI).

.PARAMETER ValidityDays
    Validade do certificado em dias. Padrao: 10000 (~27 anos). O Android nao
    aceita atualizar com um certificado vencido, entao a validade e longa de proposito.

.PARAMETER DName
    Distinguished Name do certificado. So identifica quem assinou; nao e validado
    por nenhuma CA.

.PARAMETER ProjectRoot
    Raiz do projeto Flutter. Padrao: a pasta pai deste script (portal-frontend).

.PARAMETER WriteKeyProperties
    Escreve tambem android\key.properties (ignorado pelo git), para que
    'flutter build apk --release' nesta maquina assine com o mesmo keystore do CI.

.EXAMPLE
    pwsh scripts\gen-android-keystore.ps1

.EXAMPLE
    pwsh scripts\gen-android-keystore.ps1 -WriteKeyProperties
#>
[CmdletBinding()]
param(
    [string] $OutDir = (Join-Path $env:USERPROFILE '.gja-keys'),
    [string] $Alias = 'gjamobile',
    [int]    $ValidityDays = 10000,
    [string] $DName = 'CN=Portal GJA, OU=TI, O=Refrescos Bandeirantes, L=Trindade, ST=GO, C=BR',
    [string] $ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch] $WriteKeyProperties
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# keytool escreve avisos em stderr com exit 0; sem isso o PS 7.4+ trataria como erro.
$PSNativeCommandUseErrorActionPreference = $false

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
    Write-Host "    $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string] $Message)
    Write-Host "    $Message" -ForegroundColor Yellow
}

function Resolve-Keytool {
    $candidates = @()
    if ($env:JAVA_HOME) { $candidates += (Join-Path $env:JAVA_HOME 'bin\keytool.exe') }
    $candidates += 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    $cmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw 'keytool nao encontrado. Instale um JDK ou o Android Studio, ou defina JAVA_HOME.'
}

function New-KeystorePassword {
    param([int] $Length = 32)
    # So alfanumericos, sem os ambiguos (0/O, 1/l/I): a senha vai para um arquivo
    # .properties (onde '\', '=', '#' e '!' sao especiais) e para uma variavel
    # Masked do GitLab, que so aceita um conjunto restrito de caracteres.
    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
    $chars = for ($i = 0; $i -lt $Length; $i++) {
        $alphabet[[System.Security.Cryptography.RandomNumberGenerator]::GetInt32($alphabet.Length)]
    }
    return -join $chars
}

$keystore   = Join-Path $OutDir 'gjamobile-release.jks'
$base64File = Join-Path $OutDir 'gjamobile-release.base64.txt'
$passEnv    = 'GJA_KEYSTORE_PASS'

Write-Step 'Verificando o destino'
if (Test-Path -LiteralPath $keystore) {
    throw "Ja existe um keystore em '$keystore'. Este script nunca sobrescreve: trocar o keystore impede a atualizacao do app ja instalado. Se a intencao e mesmo recomecar do zero, apague o arquivo a mao."
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Write-Info "Pasta: $OutDir"

$keytool = Resolve-Keytool
Write-Info "keytool: $keytool"

Write-Step 'Gerando o keystore (PKCS12, RSA 2048)'
$password = New-KeystorePassword
# A senha vai por variavel de ambiente (-storepass:env), e nao na linha de
# comando, para nao aparecer na lista de processos nem no historico do shell.
Set-Item -Path "Env:$passEnv" -Value $password
try {
    $genOutput = & $keytool '-J-Duser.language=en' -genkeypair `
        -keystore $keystore -storetype PKCS12 `
        -alias $Alias -keyalg RSA -keysize 2048 -validity $ValidityDays `
        -dname $DName '-storepass:env' $passEnv 2>&1
    if ($LASTEXITCODE -ne 0) {
        $genOutput | ForEach-Object { Write-Warn "$_" }
        throw "keytool -genkeypair falhou (exit $LASTEXITCODE)."
    }

    $listing = & $keytool '-J-Duser.language=en' -list -v `
        -keystore $keystore -alias $Alias '-storepass:env' $passEnv 2>&1
    if ($LASTEXITCODE -ne 0) {
        $listing | ForEach-Object { Write-Warn "$_" }
        throw "keytool -list falhou (exit $LASTEXITCODE)."
    }
}
finally {
    Remove-Item -Path "Env:$passEnv" -ErrorAction SilentlyContinue
}

$shaMatch = $listing | Select-String -Pattern 'SHA256:\s*(\S+)' | Select-Object -First 1
$sha256 = if ($shaMatch) { $shaMatch.Matches[0].Groups[1].Value } else { '<nao lido; rode keytool -list -v>' }
Write-Ok "Keystore: $keystore"

Write-Step 'Gravando o base64 para a variavel de CI'
$base64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($keystore))
Set-Content -LiteralPath $base64File -Value $base64 -NoNewline -Encoding ascii
Write-Ok "Base64: $base64File ($($base64.Length) caracteres, uma linha)"

if ($WriteKeyProperties) {
    Write-Step 'Escrevendo android\key.properties (builds locais)'
    $keyProps = Join-Path $ProjectRoot 'android\key.properties'
    if (Test-Path -LiteralPath $keyProps) {
        Write-Warn "Ja existe '$keyProps'; nao foi alterado."
    }
    else {
        # Em .properties a barra invertida e escape: o caminho vai com '/'.
        $storeFile = $keystore -replace '\\', '/'
        $lines = @(
            "storeFile=$storeFile"
            "storePassword=$password"
            "keyAlias=$Alias"
            "keyPassword=$password"
        )
        Set-Content -LiteralPath $keyProps -Value $lines -Encoding ascii
        Write-Ok "Escrito: $keyProps (ignorado pelo git)"
    }
}

Write-Host ''
Write-Host '============================================================' -ForegroundColor Green
Write-Host ' Keystore de release gerado' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Write-Host ''
Write-Host ' VARIAVEIS A CRIAR NO GITLAB' -ForegroundColor Cyan
Write-Host ' Settings > CI/CD > Variables (projeto portal-frontend)'
Write-Host ''
Write-Host ' 1) ANDROID_KEYSTORE_BASE64'
Write-Host "      Valor: TODO o conteudo do arquivo abaixo ($($base64.Length) caracteres, uma linha so)."
Write-Host "      $base64File"
Write-Host '      Para copiar para a area de transferencia:'
Write-Host "        Get-Content -Raw '$base64File' | Set-Clipboard" -ForegroundColor DarkGray
Write-Host ''
Write-Host ' 2) ANDROID_KEYSTORE_PASSWORD'
Write-Host "      Valor: $password" -ForegroundColor Yellow
Write-Host '      Aparece so agora. Guarde uma copia tambem fora do GitLab.'
Write-Host ''
Write-Host " 3) ANDROID_KEY_ALIAS (opcional; '$Alias' ja e o padrao do CI)"
Write-Host ''
Write-Host '    Nas duas primeiras: Type=Variable, Protected=SIM, Masked=SIM, scope=*'
Write-Host ''
# As impressoes digitais ficam DEPOIS e rotuladas como conferencia: na primeira
# versao a linha "SHA-256 no CI" vinha junto da senha e foi colada, por engano,
# na variavel ANDROID_KEYSTORE_BASE64 (64 hex decodificam como base64 valido).
Write-Host ' SO PARA CONFERENCIA (NAO vai em variavel nenhuma)' -ForegroundColor Cyan
Write-Host " Alias ..................................: $Alias"
Write-Host " Impressao digital do certificado (SHA-256): $sha256"
# O apksigner (log do job build_apk) imprime o mesmo digest em minusculas e sem ':'.
Write-Host " Como ela aparece no log do build_apk ...: $(($sha256 -replace ':', '').ToLowerInvariant())"
Write-Host ''
Write-Host ' Guarde no cofre de senhas da empresa: o arquivo .jks e a senha.' -ForegroundColor Yellow
Write-Host ' Perder qualquer um dos dois = nunca mais atualizar o app instalado.' -ForegroundColor Yellow
Write-Host ' Depois de criar as variaveis, apague o gjamobile-release.base64.txt.'
Write-Host '============================================================' -ForegroundColor Green
