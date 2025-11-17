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

    # Divide o texto em linhas e exibe cada uma com a cor definida
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

    # Verifica se o caminho de origem existe
    if (-Not (Test-Path $Origem)) {
        Write-Host "O caminho informado para a pasta não existe: '$Origem'" -ForegroundColor Red
        return
    }

    # Obtém o nome da pasta e monta o caminho completo de destino
    $nomePasta = Split-Path $Origem -Leaf
    $destinoCompleto = Join-Path $Destino $nomePasta

    # Cria a pasta de destino se ela não existir
    if (-Not (Test-Path $destinoCompleto)) {
        New-Item -ItemType Directory -Path $destinoCompleto | Out-Null
    }

    # Exibe informações sobre a cópia
    Write-Host ""
    Write-Host "📂 Pasta que será copiada: $Origem" -ForegroundColor Cyan
    Write-Host "📁 Destino da cópia: $destinoCompleto" -ForegroundColor Yellow
    Write-Host ""

    # Copia arquivos e subpastas recursivamente
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

    # Mensagem de sucesso
    Write-Host "✔ A pasta '$nomePasta' foi copiada e sobrescrita no destino." -ForegroundColor Green
}

# Dicionário com opções do menu e suas descrições
$menuOptions = @{
    1  = "Verificar espaço em disco"
    2  = "Listar processos"
    3  = "Stop WebPool Y"
    4  = "Start WebPool Y"
    5  = "Stop WebPoolX"
    6  = "Start WEBPoolX"
    7  = "Parar IIS"
    8  = "Iniciar IIS"
    9  = "Reiniciar IIS"
    10 = "Reconhecimento da máquina"
    11 = "Uso de CPU e Memória dos principais processos"
    12 = "Listar serviços em execução"
    13 = "Copiar CA (interativo)"
}

# Função para exibir o menu principal
function Show-Menu {
    set-ConsoleStyle
    Show-ASCII -AsciiArt $logo -Color Green
    Write-Host ""
    Write-Host "Menu de Scripts"
    Write-Host "Q. Sair" -ForegroundColor Red
    foreach ($key in ($menuOptions.Keys | Sort-Object)) {
        Write-Host "$key. $($menuOptions[$key])"
    }
}

# Função que executa o script correspondente à opção escolhida
function Run-Script {
    param (
        [string]$choice
    )

    switch ($choice.ToUpper()) {
        "Q" {
            Write-Host "Saindo..."
            exit
        }
        "1" {
            # Exibe espaço em disco das unidades
            Get-PSDrive -PSProvider 'FileSystem'
        }
        "2" {
            # Lista os 10 processos que mais consomem CPU
            Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
        }
        "3" {
            # Para pools de aplicativos do WebPool Y
            Stop-WebAppPool -Name "WebPool Y"
        }
        "4" {
            # Inicia pools de aplicativos
            Start-WebAppPool -Name "Y"
            
        }
        "5" {
            # Para o pool do Portal X
            Stop-WebAppPool -Name "PortalX"
        }
        "6" {
            # Inicia o pool do Portalxyz
            Start-WebAppPool -Name "PortalX"
        }
        "7" {
            # Para o IIS
            iisreset /stop
        }
        "8" {
            # Inicia o IIS
            iisreset /start
        }
        "9" {
            # Reinicia o IIS
            iisreset
        }
        "10" {
            # Exibe informações da máquina e IP
            $usuario = $env:USERNAME
            $maquina = $env:COMPUTERNAME
            $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -ne "127.0.0.1"} | Select-Object -First 1).IPAddress
            Write-Host "Usuário logado: $usuario"
            Write-Host "Nome da máquina: $maquina"
            Write-Host "Endereço IP: $ip"
        }
        "11" {
            # Exibe os 10 processos que mais consomem CPU e memória
            Write-Host "===== USO DE CPU E MEMÓRIA ====="
            Get-Process |
            Sort-Object CPU -Descending |
            Select-Object -First 10 -Property Name, CPU, WorkingSet |
            Format-Table -AutoSize
            Write-Host "`nObservação: WorkingSet é a memória usada em bytes."
        }
        "12" {
            # Lista serviços em execução
            Write-Host "===== SERVIÇOS EM EXECUÇÃO ====="
            Get-Service |
            Where-Object {$_.Status -eq 'Running'} |
            Select-Object Name, DisplayName, Status |
            Sort-Object Name |
            Format-Table -AutoSize
        }
        "13" {
            # Executa cópia de pasta de forma interativa
            $origem = Read-Host "Digite o caminho completo da pasta que será copiada (ex: C:\Users\MeuUser\Documents\Teste1\pasta1)"
            $destino = Read-Host "Digite o caminho do destino da cópia (ex: C:\Teste)"
            Copiar-Pasta -Origem $origem -Destino $destino
        }
        default {
            # Mensagem para opção inválida
            Write-Host "Opção inválida. Tente novamente."
        }
    }
}

# Loop principal que exibe o menu e executa ações até o usuário sair
do {
    Show-Menu
    $userChoice = Read-Host "Escolha uma opção (ou Q para sair)"
    Run-Script -choice $userChoice
    Pause
} while ($true)
