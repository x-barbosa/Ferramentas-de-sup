# ===============================
# Fast Script
# ===============================
# Versão: 1.6
# Última modificação: 03/10/2025
# ===============================

function set-ConsoleStyle {
    $host.ui.RawUI.ForegroundColor = "Green"
    $host.ui.RawUI.BackgroundColor = "Black"
    Clear-Host
}

function Show-ASCII {
    param (
        [string]$AsciiArt,
        [string]$Color = "Green"
    )
    $AsciiArt -split "`n" | ForEach-Object {
        Write-Host $_ -ForegroundColor $Color
    }
}

$logo = @"
Versão: 1.6

  ______        _      _____           _       _   
 |  ____|      | |    / ____|         (_)     | |  
 | |__ __ _ ___| |_  | (___   ___ _ __ _ _ __ | |_ 
 |  __/ _` / __| __|  \___ \ / __| '__| | '_ \| __| 
 | | | (_| \__ \ |_   ____) | (__| |  | |_) | |_ 
 |_|  \__,_|___/\__| |_____/ \___|_|  |_| .__/ \__| 
                                        | |         
                                        |_|         
"@

Show-ASCII -AsciiArt $logo -Color Green
Start-Sleep -Seconds 2

# ---------- Helpers de LOG ----------
function Ensure-DefaultLogPath {
    param([string]$Opcao)
    $pastaDefault = "C:\Logs\FastScript"
    if (-not (Test-Path $pastaDefault)) {
        New-Item -ItemType Directory -Path $pastaDefault -Force | Out-Null
    }
    return Join-Path $pastaDefault "opcao$Opcao.txt"
}

function Perguntar-Log {
    param(
        [string]$Opcao,
        [ScriptBlock]$Comando
    )

    $resposta = Read-Host "Deseja gerar log para a opção $Opcao? (S/N)"
    if ($resposta -match '^[Ss]$') {
        $caminhoLog = Read-Host "Digite o caminho completo para salvar o log (ou pressione Enter para usar o padrão)"
        if ([string]::IsNullOrWhiteSpace($caminhoLog)) {
            $caminhoLog = Ensure-DefaultLogPath -Opcao $Opcao
        } else {
            # Se usuário não colocou .txt, anexar .txt
            if (-not ($caminhoLog.ToLower().EndsWith(".txt"))) {
                $caminhoLog = "$caminhoLog.txt"
            }
            $dir = Split-Path $caminhoLog -Parent
            if ($dir -and -not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
        }

        try {
            # Executa e duplica saída para tela e arquivo
            & $Comando | Tee-Object -FilePath $caminhoLog -Append
            Write-Host "✔ Log salvo em: $caminhoLog" -ForegroundColor Green
        } catch {
            Write-Host "❌ Erro ao salvar log: $_" -ForegroundColor Red
        }
    } else {
        & $Comando
    }
}

# ---------- Função para copiar pasta ----------
function Copiar-Pasta {
    param(
        [string]$Origem,
        [string]$Destino
    )

    if (-Not (Test-Path $Origem)) {
        Write-Host "O caminho informado para a pasta não existe: '$Origem'" -ForegroundColor Red
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

    Write-Host "✔ A pasta '$nomePasta' foi copiada e sobrescrita no destino." -ForegroundColor Green
}

# ---------- Decode helper for DigitalProductId ----------
function Decode-DigitalProductId {
    param(
        [Parameter(Mandatory=$true)][byte[]]$DigitalProductId
    )
    # Retorna chave decodificada ou $null em caso de falha
    try {
        $map = "BCDFGHJKMPQRTVWXY2346789".ToCharArray()
        # Clona array para não mutar o original
        $digital = ,0 * $DigitalProductId.Length
        [Array]::Copy($DigitalProductId, $digital, $DigitalProductId.Length)

        # usar offset de 52 (método clássico)
        $i = 52
        $key = ""
        for ($j = 24; $j -ge 0; $j--) {
            $k = 0
            for ($l = 14; $l -ge 0; $l--) {
                $k = ($k * 256) -bxor $digital[$l + $i]
                $digital[$l + $i] = [math]::Floor($k / 24)
                $k = $k % 24
            }
            $key = $map[$k] + $key
            if (($j % 5) -eq 0 -and $j -ne 0) { $key = "-" + $key }
        }
        return $key
    } catch {
        return $null
    }
}

# ---------- Função: Decodifica DigitalProductId do Windows (usa Decode-DigitalProductId) ----------
function Get-WindowsProductKey {
    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $dp = Get-ItemProperty -Path $regPath -Name "DigitalProductId" -ErrorAction Stop
        $digital = $dp.DigitalProductId
        if ($digital -is [byte[]]) {
            $decoded = Decode-DigitalProductId -DigitalProductId $digital
            if ($decoded) {
                Write-Output ("Windows | Key: {0}" -f $decoded)
                return
            } else {
                Write-Output "Windows | Key: encontrado DigitalProductId, mas falha ao decodificar."
                return
            }
        } else {
            # tentar obter ProductId ou ProductKey direto
            if ($dp.ProductId) {
                Write-Output ("Windows | ProductId (não é chave de ativação): {0}" -f $dp.ProductId)
                return
            }
            Write-Output "Windows | Key: não encontrada."
            return
        }
    } catch {
        Write-Output "Windows | Key: não encontrada (permissão/registro indisponível)."
        return
    }
}

# ---------- Função: Procura por possíveis chaves/licenças de softwares na Registry ----------
function Get-SoftwareKeys {
    <#
    Varre locais comuns da Registry em HKLM e HKCU procurando valores que contenham "Key","ProductKey","ProductId","DigitalProductId","License","Serial".
    Exibe: Software: <DisplayName> | Key: <valor ou mensagem>
    #>
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    Write-Output "===== Buscando chaves/licenças na Registry (locais comuns) ====="

    foreach ($p in $paths) {
        try {
            $items = Get-ChildItem -Path $p -ErrorAction SilentlyContinue
            foreach ($it in $items) {
                try {
                    $props = Get-ItemProperty -Path $it.PSPath -ErrorAction SilentlyContinue
                    if ($null -eq $props) { continue }

                    $displayName = $props.DisplayName
                    if ([string]::IsNullOrWhiteSpace($displayName)) { continue }

                    $foundKey = $null

                    # procura por propriedades conhecidas que podem conter chaves
                    $candidates = @("ProductKey","ProductId","License","Serial","Key","ActivationKey","SoftSerial")
                    foreach ($cand in $candidates) {
                        if ($props.PSObject.Properties.Name -contains $cand) {
                            $val = $props.$cand
                            if ($val) {
                                $foundKey = $val
                                break
                            }
                        }
                    }

                    # se não encontrou em nomes explícitos, procura por qualquer propriedade que contenha "Key","Product" etc
                    if (-not $foundKey) {
                        foreach ($propName in $props.PSObject.Properties.Name) {
                            if ($propName -match "(?i)Product(key|id)|DigitalProductId|License|Serial|Key$|ActivationKey") {
                                $val = $props.$propName
                                if ($val) {
                                    $foundKey = @{ Name = $propName; Value = $val }
                                    break
                                }
                            }
                        }
                    }

                    # tratar DigitalProductId (bytes)
                    if ($foundKey -and $foundKey -is [hashtable] -and ($foundKey.Value -is [byte[]] -or $foundKey.Value -is [System.Byte[]])) {
                        $decoded = Decode-DigitalProductId -DigitalProductId $foundKey.Value
                        if ($decoded) {
                            Write-Output ("Software: {0} | Key ({1}): {2}" -f $displayName, $foundKey.Name, $decoded)
                        } else {
                            Write-Output ("Software: {0} | Key ({1}): DigitalProductId detectado (bytes) — impossível decodificar aqui" -f $displayName, $foundKey.Name)
                        }
                        continue
                    }

                    # se foundKey é valor simples
                    if ($foundKey -and -not ($foundKey -is [hashtable])) {
                        Write-Output ("Software: {0} | Key: {1}" -f $displayName, $foundKey)
                        continue
                    } elseif ($foundKey -and ($foundKey -is [hashtable])) {
                        Write-Output ("Software: {0} | {1}: {2}" -f $displayName, $foundKey.Name, $foundKey.Value)
                        continue
                    }

                    # se nada encontrado explicitamente, tentar varrer valores literais que pareçam chave
                    $maybe = $null
                    foreach ($propName in $props.PSObject.Properties.Name) {
                        $val = $props.$propName
                        if ($val -is [string] -and $val.Length -ge 16) {
                            # heurística: strings com 16+ chars que contenham letras/números e possuam traços
                            if ($val -match "[A-Za-z0-9\-]{5,}") {
                                $maybe = $val
                                break
                            }
                        }
                    }
                    if ($maybe) {
                        Write-Output ("Software: {0} | Key (possível): {1}" -f $displayName, $maybe)
                    } else {
                        # não encontrou chave explícita
                        Write-Output ("Software: {0} | Key: não encontrada (ou ativação online/armazenamento proprietário)" -f $displayName)
                    }

                } catch {
                    # ignora entradas problemáticas
                    continue
                }
            }
        } catch {
            continue
        }
    }

    Write-Output "===== Busca finalizada ====="
    Write-Output "Observação: muitas aplicações modernas usam ativação online e não expõem chaves em texto legível na Registry."
}

# ---------- Menu ----------
$menuOptions = @{
    1  = "Verificar espaço em disco"
    2  = "Listar processos"
    3  = "Stop portal y"
    4  = "Start portal y"
    5  = "Stop Portal x"
    6  = "Start Portal x"
    7  = "Parar IIS"
    8  = "Iniciar IIS"
    9  = "Reiniciar IIS"
    10 = "Reconhecimento da máquina"
    11 = "Uso de CPU e Memória dos principais processos"
    12 = "Listar serviços em execução"
    13 = "Copiar pasta(interativo)"
    14 = "Exibir chaves do Windows e softwares"
}

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

function Run-Script {
    param (
        [string]$choice
    )

    switch ($choice.ToUpper()) {
        "Q" { Write-Host "Saindo..."; exit }

        "1" {
            Perguntar-Log -Opcao "1" -Comando { Get-PSDrive -PSProvider 'FileSystem' | Format-Table -AutoSize | Out-String }
        }

        "2" {
            Perguntar-Log -Opcao "2" -Comando { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 | Format-Table -AutoSize | Out-String }
        }

        "3" {
            Stop-WebAppPool -Name "y"
        }

        "4" {
            Start-WebAppPool -Name "y"
        }

        "5" { Stop-WebAppPool -Name "x" }

        "6" { Start-WebAppPool -Name "x" }

        "7" { iisreset /stop }

        "8" { iisreset /start }

        "9" { iisreset }

        "10" {
            Perguntar-Log -Opcao "10" -Comando {
                $usuario = $env:USERNAME
                $maquina = $env:COMPUTERNAME
                $ip = (Get-NetIPAddress -AddressFamily IPv4 |
                       Where-Object {$_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*"} |
                       Select-Object -First 1 -ExpandProperty IPAddress)
                $soObj = Get-CimInstance Win32_OperatingSystem
                $so = $soObj.Caption + " " + $soObj.OSArchitecture
                $boot = $soObj.LastBootUpTime
                $uptime = (Get-Date) - ([Management.ManagementDateTimeConverter]::ToDateTime($boot))
                $bootFormatted = ([Management.ManagementDateTimeConverter]::ToDateTime($boot)).ToString("yyyy-MM-dd HH:mm:ss")

                Write-Output "===== INFORMAÇÕES DA MÁQUINA ====="
                Write-Output "👤 Usuário logado  : $usuario"
                Write-Output "💻 Nome da máquina : $maquina"
                Write-Output "🌐 Endereço IP     : $ip"
                Write-Output "🖥️ Sistema         : $so"
                Write-Output ("🕒 Último boot     : {0} (uptime: {1}d {2}h {3}m)" -f $bootFormatted, $uptime.Days, $uptime.Hours, $uptime.Minutes)
            }
        }

        "11" {
            Perguntar-Log -Opcao "11" -Comando {
                Write-Output "===== TOP 10 PROCESSOS - CPU E MEMÓRIA ====="
                Get-Process |
                Sort-Object CPU -Descending |
                Select-Object -First 10 |
                ForEach-Object {
                    $memMB = [math]::Round($_.WorkingSet / 1MB, 2)
                    $cpuSec = if ($_.CPU) { [math]::Round($_.CPU, 2) } else { 0 }
                    Write-Output ("📌 {0,-30} | CPU: {1,6} seg | Memória: {2,8} MB" -f $_.ProcessName, $cpuSec, $memMB)
                }
            }
        }

        "12" {
            Perguntar-Log -Opcao "12" -Comando {
                Write-Output "===== SERVIÇOS EM EXECUÇÃO ====="
                Get-Service |
                Where-Object {$_.Status -eq 'Running'} |
                Select-Object Name, DisplayName, Status |
                Sort-Object Name |
                Format-Table -AutoSize | Out-String
            }
        }

        "13" {
            $origem = Read-Host "Digite o caminho completo da pasta que será copiada"
            $destino = Read-Host "Digite o caminho do destino da cópia"
            Copiar-Pasta -Origem $origem -Destino $destino
        }

        "14" {
            # Exibir chaves do Windows e softwares
            Perguntar-Log -Opcao "14" -Comando {
                Write-Output "===== CHAVE DO WINDOWS ====="
                Get-WindowsProductKey
                Write-Output ""
                Write-Output "===== CHAVES / LICENÇAS DE SOFTWARE (REGISTRY) ====="
                Get-SoftwareKeys
                Write-Output ""
                Write-Output "Observação: algumas chaves podem não estar disponíveis em texto claro (ativação online ou formatos proprietários)."
            }
        }

        default {
            Write-Host "Opção inválida. Tente novamente."
        }
    }
}

do {
    Show-Menu
    $userChoice = Read-Host "Escolha uma opção (ou Q para sair)"
    Run-Script -choice $userChoice
    Pause
} while ($true)
