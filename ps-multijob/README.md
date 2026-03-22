# ps-multijob

![image](https://user-images.githubusercontent.com/82112471/205506429-6e86cadc-985c-488a-9dce-78a6b5aec1bb.png)

Um script com design moderno e elegante para exibir seus empregos atuais e permitir alternar entre eles.

## Funcionalidades

* Permite ignorar determinados empregos via configuração.
* Permite configurar a tecla para abrir o menu de empregos - J por padrão.
* Permite configurar o número máximo de empregos por citizen ID. Jogadores com a permissão 'admin' têm empregos ilimitados.
* Permite configurar empregos whitelist.
* Permite configurar descrições para cada emprego.
* Permite configurar o lado da tela (esquerdo ou direito) onde a interface será exibida. Lado direito por padrão. (veja Config)
* Permite configurar ícones de empregos com Font Awesome. Altere esses ícones no config.
* Remove o emprego de alguém com /removejob - somente admin.
* Em breve: aba administrativa para gerenciar empregos.

## Prévia

![image](https://user-images.githubusercontent.com/82112471/206809426-155ad6fd-50d0-4ff9-add0-d72ae00f2304.png)

## Instalação

* Renomeie para ps-multijob. Não altere o nome ou não funcionará.
* Importe o [SQL](https://github.com/Project-Sloth/ps-multijob/blob/main/database.sql) para o seu banco de dados.
* Adicione ao server.cfg

### Integração com qb-management | Demissão automática

1. Encontre o seguinte evento

    ```txt
    qb-bossmenu:server:FireEmployee
    ```

2. Insira o TriggerEvent logo abaixo da notificação de 'Employee Fired!'. O TriggerEvent deve ser adicionado duas vezes, uma perto da linha 174 e outra perto da linha 199.

    ```lua
    TriggerClientEvent('QBCore:Notify', src, "Employee fired!", "success")
    TriggerEvent('ps-multijob:server:removeJob', target)
    ```

## Uso

### Exports do servidor

* GetJobs(citizenid)

    Exemplo de uso:

    ```lua
    local jobs = exports["ps-multijob"]:GetJobs("citizenid here")
    ```

* AddJob(citizenid, job, grade)

    Exemplo de uso:

    ```lua
    exports["ps-multijob"]:AddJob("citizenid here", "police", 0)
    ```

* UpdateJobRank(citizenid, job, grade)
    Exemplo de uso:

    ```lua
    exports["ps-multijob"]:UpdateJobRank("citizenid here", "police", 3)
    ```

* RemoveJob(citizenid, job)

    Exemplo de uso:

    ```lua
    exports["ps-multijob"]:RemoveJob("citizenid here", "police")
    ```

## Créditos

* [xFutte](https://github.com/xFutte)
* [Silent](https://github.com/S1lentcodes)
* [Jay](https://github.com/jay-fivem)
* [Snipe](https://github.com/pushkart2)
