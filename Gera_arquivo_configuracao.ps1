# Um script simples que gera o aruqivo base com pastas com o nome do ramal e o arquivo de configuração

# Definimos que queremos que para cada linha do arquivo ele execute os comandos abaixo.
foreach($linha in Get-Content \\pr6534et012\CONFIG3CX\DADOS\baia_ramal.txt)
    {
        # Os dados abaixo podem ser alteados para se adequar a seu ambiente de trabalho.

        $linha = $linha -split ";" # Separamos as linhas com o delimitador ";". 
        $ramal = $linha[1] # Extraimos e armazenamos o ramal do arquivo.
        $baia = $linha[0] # Extraimos e armazenamos a baia do arquivo.
        
        # Criamos a nova pasta com o nome da baia.
        New-Item -Path \\pr6534et012\CONFIG3CX\BAIAS\$baia -ItemType "directory"
        
        # Neste caso copiamos os arquivos base para dentro da pasta, mas com o .ini tortalmente vazio
        cp -Recurse \\pr6534et012\CONFIG3CX\BASE\* "\\pr6534et012\CONFIG3CX\BAIAS\$baia"

        <# Armazenamos o arquivo de configuração dentro da váriavel com o ramal extraido.
           O arquivo está no padrão criado pelo 3CXphone
           Recomendo que inicie e crie um ramal uma primeira vez e configure o 3CX com todo o padrão do seu ambiente de trabalho.
           E utilize este arquivo como modelo alterando apenas os parêmtros abaixo para inserir o ramal automáticamente. #>
        $arquivo = ("[Profile0] 
        Name=$ramal
        CallerID=$ramal
        AuthUser=$ramal
        AuthID=$ramal
        ") 
        
        # Definimos out-file realize um apeend com o conteúdo da variavel $arquivo dentro do arquivo de configuração.
        $arquivo | out-file -FilePath \\pr6534et012\CONFIG3CX\BAIAS\$baia\3CXVoipPhone.ini

    }
