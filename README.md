🟩 FastScript — Automação Rápida em PowerShell

O FastScript é uma ferramenta criada para agilizar tarefas de suporte técnico e administração de sistemas em ambientes Windows.
Ele serve como um switch centralizado de scripts, permitindo que diferentes funções sejam executadas de forma rápida, padronizada e organizada por meio de um menu interativo.

Ideal para analistas de suporte, infraestrutura e times de TI que lidam com rotinas repetitivas.

⚙️ Funcionalidades Gerais

Menu interativo em PowerShell

Execução rápida de múltiplos scripts internos

Layout temático (texto verde em fundo preto)

Registro opcional de logs

Funções utilitárias prontas para uso

Estrutura pensada para expansão

Suporte à execução via arquivo .bat com caminho configurável

📚 Lista Completa de Funções do FastScript
🎨 Funções de Interface

set-ConsoleStyle
Define estilo visual do console (verde no preto).

Show-ASCII
Exibe arte ASCII personalizada.

🧰 Funções Utilitárias

Ensure-DefaultLogPath
Garante que o diretório padrão de logs existe.

Perguntar-Log
Pergunta ao usuário se deseja registrar log da execução.

Copiar-Pasta
Realiza cópia de pastas de forma automatizada.

Decode-DigitalProductId
Decodifica a chave do Windows a partir do registro.

Get-WindowsProductKey
Recupera a chave de licença do Windows.

Get-SoftwareKeys
Recupera chaves de softwares instalados compatíveis.

🧭 Menu e Execução

Show-Menu
Exibe as opções disponíveis no FastScript.

Run-Script
Switch principal que identifica qual script deve ser executado conforme a escolha do usuário.

▶️ Como Executar o FastScript
1️⃣ ⭐ Executando diretamente pelo PowerShell

Abra o PowerShell na pasta onde o FastScript está salvo e execute:

.\FastScript.ps1

Se a execução estiver bloqueada:
Set-ExecutionPolicy Bypass -Scope Process -Force

2️⃣ ⭐ Executando pelo arquivo .bat (maneira mais fácil)

O repositório contém um arquivo .bat que permite abrir o FastScript com apenas um duplo clique.

Para configurá-lo:

Abra o .bat com o bloco de notas.

Edite o caminho do script PowerShell.

Coloque o diretório onde você deixou o FastScript.ps1.

Exemplo de .bat configurado:
@echo off
powershell -executionpolicy bypass -File "C:\SEU_DIRETORIO\FastScript.ps1"
pause


🔧 Basta alterar o caminho acima para o local correto no seu computador.

➕ Como Adicionar Novos Scripts ao FastScript

O FastScript foi projetado para ser facilmente expandido.
Para inserir um novo script, siga estes passos:

1️⃣ Criar uma nova função
function Meu-NovoScript {
    Write-Host "Meu novo script está rodando!"
}

2️⃣ Adicionar opção ao menu

Dentro da função Show-Menu, adicione:

Write-Host "7 - Executar Meu-NovoScript"

3️⃣ Registrar no mecanismo de execução

Dentro de Run-Script, adicione:

"7" { Meu-NovoScript }

🛠 Como Realizar Alterações no Código

Todas as funções ficam organizadas no topo do script.

Funções podem ser editadas diretamente no arquivo .ps1.

O menu é totalmente personalizável.

Você pode remover, renomear ou substituir scripts sem quebrar a ferramenta, desde que edite também:

Show-Menu

Run-Script
