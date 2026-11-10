#Requires -Version 7.0
<#
.SYNOPSIS
    Bootstrap de shell do Portal GJA - registra o wrapper do comando `flutter`.

.DESCRIPTION
    Carregue com dot-source para habilitar `flutter execCICDDesktop` na sessao:

        . <repo>\scripts\gja-shell.ps1

    Depois disso:
        flutter execCICDDesktop            # clean + pub get + build + publica na rede
        flutter execCICDDesktop -SkipClean # build incremental
        flutter <qualquer outra coisa>     # repassado intacto ao flutter.bat real

    Carregado automaticamente pelo terminal integrado do VS Code (perfil
    "PowerShell (GJA)" em .vscode/settings.json). Para habilitar tambem no
    Windows Terminal, adicione ao seu $PROFILE:

        . 'C:\caminho\do\repo\scripts\gja-shell.ps1'

    Para desativar o wrapper na sessao atual: Remove-Item Function:\flutter
#>

# Resolvido no carregamento -> funciona em qualquer maquina/clone, sem caminho fixo.
$global:GjaPortalScriptsDir = $PSScriptRoot

function flutter {
    $cicdScript = Join-Path $global:GjaPortalScriptsDir 'exec-cicd-desktop.ps1'

    if ($args.Count -gt 0 -and "$($args[0])" -eq 'execCICDDesktop') {
        if (-not (Test-Path -LiteralPath $cicdScript)) {
            Write-Error "Script de release nao encontrado: $cicdScript"
            return
        }
        # splatting exige uma variavel (@nome), nao uma expressao
        $cicdArgs = @($args | Select-Object -Skip 1)
        & $cicdScript @cicdArgs
        return
    }

    # -CommandType Application garante que resolvemos o executavel real,
    # nunca esta funcao (evita recursao infinita).
    $real = foreach ($name in @('flutter.bat', 'flutter')) {
        $found = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue |
                 Select-Object -First 1
        if ($found) { $found; break }
    }

    if (-not $real) {
        Write-Error 'flutter nao encontrado no PATH.'
        return
    }

    & $real.Source @args
}
