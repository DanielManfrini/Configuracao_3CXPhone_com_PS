# DECLARAÇÂO DE FUNÇÕES
# Declaramos a função para intalar o 3CX caso não exista na máquina

Function Trigger-AppInstallation {
# Esta função foi escrita por Timmy Andersson
# Site fonte https://timmyit.com/2016/08/01/sccm-and-powershell-force-install-of-software-updates-thats-available-on-client-through-wmi/
#definimos os seguintes parâmetros para a função.
Param
(
 [String][Parameter(Mandatory=$True, Position=1)] $Computername, # Nome do cumputador, será sempre LocalHost.
 [String][Parameter(Mandatory=$True, Position=2)] $AppName, # Nome da aplicacao será "3CXPhone".
 [ValidateSet("Install","Uninstall")]
 [String][Parameter(Mandatory=$True, Position=3)] $Method # Metodo será instalar.
)
 
Begin {

<# Em seguida, é o bloco Begin, onde estamos apenas obtendo a instância CIM para esse aplicativo específico do computador remoto, 
depois reunimos os argumentos necessários de que precisamos mais tarde, quando vamos invocar o método CIM no bloco de processo. 
Os únicos 2 argumentos que mantive estáticos foram IsRebootIfNeeded = $False, o que significa que ele não será reinicializado ao instalar ou desinstalar o aplicativo, 
se você definir este como $True, ele será reinicializado. e Prioridade eu mantive como “Alta” porque por que não certo? #>
$Application = (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" -ComputerName $Computername | Where-Object {$_.Name -like $AppName})
 
$Args = @{EnforcePreference = [UINT32] 0
Id = "$($Application.id)"
IsMachineTarget = $Application.IsMachineTarget
IsRebootIfNeeded = $False
Priority = 'High'
Revision = "$($Application.Revision)" }
 
}
 
<# O bloco de processo, aqui estamos chamando o método que é Instalar ou Desinstalar na instância CIM específica. 
Passando pelo nome do computador, método e argumentos anteriores. 
Informações sobre o método em si você pode encontrar em Microsoft https://msdn.microsoft.com/en-us/library/jj902785.aspx mas, 
infelizmente, às vezes a documentação não parece estar 100% correta, mas menos ainda é um ótimo ponto de partida. #>
Process
 
{
 
Invoke-CimMethod -Namespace "root\ccm\clientSDK" -ClassName CCM_Application -ComputerName $Computername -MethodName $Method -Arguments $Args
 
}
 
End {}
 
}

# Declaramos a função para configurar o 3CX.
Function Configura-3cx{

    #abrindo aplicativo:
    # Acessa a pasta do aplicativo para executar e criar as pastas.
    Cd "C:\Program Files (x86)\3CXPhone" 

    # Inicia o app
    Start -WindowStyle Minimized 3CXPhone.exe  

    # Aguarda o inicio do app por 10 segundos antes de seguir
    Start-Sleep -Seconds 30 

    # Fecha o app
    Stop-process -name 3CXPhone

    
    
    # Buscar as informações da máquina: 
    # Busca o hostname da máquina
    $hostname = Hostname 

    # Faz a busca do usuario
    $user = gwmi win32_computersystem -ComputerName $hostname 
    $user = $user.UserName 
    $user = $user -split "\\"
    $user = $user[1]


    # Buscar a baia para copiar a configuração correta
    # Deve se manter o arquivo ponteiro sempre atualizado, neste caso o baias_et.txt é atualizado a cada 1 minuto.
    # Busca a baia da máquina
    $linha = Cat \\pr6534et012\CONFIG3CX\DADOS\baias_et.txt | Select-String -Pattern $hostname 

    # Splita a linha
    $linha = $linha -split ',',0 

    # Pega a baia de dentro do objeto
    $baia = $linha[0] 

    # Copia os arquivos de configuração da pasta para a máquina.
    cp -Recurse \\pr6534et012\CONFIG3CX\BAIAS\$baia\* "c:\users\$user\AppData\Local\3CX VoIP Phone"

    echo "configurado com sucesso"
}

# Declaramos a função para instalar o 3CX.
Function Instala-3cx{

<#  O programa não está instalado.
    Então o script irá realizar a intalação do aplicativo e retornar ao inicio #>
   
    # Vamos abrir a central de software para acompanhar. 
    cmd.exe /c "C:\Windows\CCM\ClientUX\SCClient.exe softwarecenter:SoftwareID=ScopeId_78BCFA31-B92C-4145-9F51-50020C0D7176/Application_9b02c084-f55e-4b46-8833-baea86c5b6c2"
    
    #esperamos o processo inicar antes de fechar o cmd.
    Start-Sleep -Seconds 2

    # Fechamos o CMD para não ficar na tela
    Stop-Process -name cmd

    #iniciamos a intalação do 3CXPhone.
    Trigger-AppInstallation -Computername localhost -AppName "3CXPhone" -Method Install

    # Esperamos 30 segundoa para intalar.
    Start-Sleep -Seconds 30
    
    # Definimos um pequeno contador para dar inicio a loop while
    $count = 0
    
    # Como PS não tem função GO-To definimos um loop wile para verificar quando o app vai ser instalado. 
    while($count -eq 0 ){
        
        <#  iniciamos verificando se o app está istalado com um Test-Path.
            se sim: irá parar o loop e começar a configuração.
            se não: continuara esperando. #>

        if (Test-path -path "C:\Program Files (x86)\3CXPhone\3CXPhone.exe"){
            echo "Instalação bem sucedida"
            $count = 1
        }
        else{
            Start-Sleep -Seconds 5
            echo "Instalação em andamento"
            $count = 0
        }
    }
    Start-Sleep -Seconds 5
    echo "iniciando configuração"
    Configura-3cx
}


# EXECUÇÃO

<#  o script abaixo irá configurar e se nescessário instalar automaticamente o 3CXPhone se ele estiver instalado na máquina do operador.

    iniciamos verificando se o app está istalado com um Test-Path.
    se sim: irá iniciar o script.
    se não: por hora só ira fechar. #>
if (Test-path -path "C:\Program Files (x86)\3CXPhone\3CXPhone.exe"){
    
    # O teste lógico verificou que o caminho existe e irá executar a função abaixo.
    # Chamamos a função de configuração
    Configura-3cx
     
}
else{
    
    # O teste lógico verificou que o caminho não existe e irá executar a função abaixo.
    # Chamamos a função de instalação e configuração
    Instala-3cx
    
}
