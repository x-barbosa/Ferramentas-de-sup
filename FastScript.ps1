# ===============================
# Fast Script
# ===============================

# Função para definir o estilo do console (texto verde sobre fundo preto)
function set-ConsoleStyle {
    $host.ui.RawUI.ForegroundColor = "Green"
    $host.ui.RawUI.BackgroundColor = "Black"
    Clear-Host
}

# Função para exibir arte ASCII com cor personalizada
function Show-ASCII {
    param (
        [string]$AsciiArt,
        [string]$Color = "Green"
    )

    $AsciiArt -split "`n" | ForEach-Object {
        Write-Host $_ -ForegroundColor $Color
    }
}

# Arte ASCII que representa o logo do script
$logo = @"
Versão: 1.2

  ______        _      _____           _       _   
 |  ____|      | |    / ____|         (_)     | |  
 | |__ __ _ ___| |_  | (___   ___ _ __ _ _ __ | |_ 
 |  __/ _` / __| __|  \___ \ / __| '__| | '_ \| __| 
 | | | (_| \__ \ |_   ____) | (__| |  | | |_) | |_ 
 |_|  \__,_|___/\__| |_____/ \___|_|  |_| .__/ \__| 
                                        | |         
                                        |_|         
"@

# Exibe o logo e aguarda 5 segundos
Show-ASCII -AsciiArt $logo -Color Green
Start-Sleep -Seconds 5

# Função para copiar uma pasta de origem para destino
function Copiar-Pasta {
    param(
        [string]$Origem,
        [string]$Destino
    )

    if (-Not (Test-Path $Origem)) {
        Write-Host "O caminho informado não existe: '$Origem'" -ForegroundColor Red
        return
    }

    $nomePasta = Split-Path $Origem -Leaf
    $destinoCompleto = Join-Path $Destino $nomePasta

    if (-Not (Test-Path $destinoCompleto)) {
        New-Item -ItemType Directory -Path $destinoCompleto | Out-Null
    }

    Write-Host ""
    Write-Host "📂 Pasta que será copiada: $Origem" -ForegroundColor Cyan
    Write-Host "📁 Destino da cópia: $destinoCompleto" -ForegroundColor Yellow
    Write-Host ""

    Get-ChildItem -Path $Origem -Recurse | ForEach-Object {
        $dest = $_.FullName.Replace($Origem, $destinoCompleto)

        if ($_.PSIsContainer) {
            if (-Not (Test-Path $dest)) {
                New-Item -ItemType Directory -Path $dest | Out-Null
            }
        } else {
            Copy-Item -Path $_.FullName -Destination $dest -Force
        }
    }

    Write-Host "✔ A pasta '$nomePasta' foi copiada com sucesso!" -ForegroundColor Green
}

# Menu de opções
$menuOptions = @{
    1  = "Verificar espaço em disco"
    2  = "Listar processos"
    3  = "Stop WebPool Y"
    4  = "Start WebPool Y"
    5  = "Stop WebPool X"
    6  = "Start WebPool X"
    7  = "Parar IIS"
    8  = "Iniciar IIS"
    9  = "Reiniciar IIS"
    10 = "Reconhecimento da máquina"
    11 = "Uso de CPU e Memória"
    12 = "Listar serviços em execução"
    13 = "Copiar pasta (interativo)"
}

# Função para mostrar o menu
function Show-Menu {
    set-ConsoleStyle
    Show-ASCII -AsciiArt $logo -Color Green
    Write-Host ""
    Write-Host "MENU PRINCIPAL"
    Write-Host "Q. Sair" -ForegroundColor Red

    foreach ($key in ($menuOptions.Keys | Sort-Object)) {
        Write-Host "$key. $($menuOptions[$key])"
    }
}

# Função que executa a opção selecionada
function Run-Script {
    param (
        [string]$choice
    )

    switch ($choice.ToUpper()) {
        "Q" { Write-Host "Saindo..."; exit }

        "1" { Get-PSDrive -PSProvider 'FileSystem' }

        "2" {
            Get-Process |
            Sort-Object CPU -Descending |
            Select-Object -First 10
        }

        "3" { Stop-WebAppPool -Name "WebPool Y" }
        "4" { Start-WebAppPool -Name "WebPool Y" }
        "5" { Stop-WebAppPool -Name "PortalX" }
        "6" { Start-WebAppPool -Name "PortalX" }

        "7" { iisreset /stop }
        "8" { iisreset /start }
        "9" { iisreset }

        "10" {
            $usuario = $env:USERNAME
            $maquina = $env:COMPUTERNAME
            $ip = (Get-NetIPAddress -AddressFamily IPv4 |
                Where-Object { $_.IPAddress -ne "127.0.0.1" } |
                Select-Object -First 1).IPAddress

            Write-Host "Usuário logado: $usuario"
            Write-Host "Máquina: $maquina"
            Write-Host "IP: $ip"
        }

        "11" {
            Write-Host "===== USO DE CPU E MEMÓRIA ====="

            Get-Process |
            Sort-Object CPU -Descending |
            Select-Object -First 10 -Property Name, CPU, WorkingSet |
            Format-Table -AutoSize

            Write-Host "`nObs: WorkingSet = memória usada (bytes)."
        }

        "12" {
            Write-Host "===== SERVIÇOS EM EXECUÇÃO ====="

            Get-Service |
            Where-Object { $_.Status -eq 'Running' } |
            Select-Object Name, DisplayName, Status |
            Sort-Object Name |
            Format-Table -AutoSize
        }

        "13" {
            $origem = Read-Host "Digite o caminho completo da pasta de origem"
            $destino = Read-Host "Digite o caminho de destino"
            Copiar-Pasta -Origem $origem -Destino $destino
        }

        default { Write-Host "Opção inválida." -ForegroundColor Red }
    }
}

# Loop principal
do {
    Show-Menu
    $userChoice = Read-Host "Escolha uma opção (ou Q para sair)"
    Run-Script -choice $userChoice
    Pause
} while ($true)
