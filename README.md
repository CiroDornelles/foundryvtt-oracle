# 🚀 Foundry VTT na Oracle Cloud (IaC)

Este projeto oferece uma solução completa de **Infraestrutura como Código (IaC)** para provisionar e configurar um servidor [Foundry Virtual Tabletop](https://foundryvtt.com/) na camada **"Always Free" da Oracle Cloud Infrastructure (OCI)**. Com um único script, você pode gerenciar todo o ciclo de vida do seu servidor de forma automatizada, resiliente e segura.


## ✨ Visão Geral dos Recursos

-   **Infraestrutura como Código (IaC):** Toda a infraestrutura (Máquina Virtual, Rede Virtual, IP Público, Regras de Firewall) é definida e gerenciada com **Terraform**.
-   **Gerenciamento de Configuração via Containers:** O software (Foundry VTT, Caddy, No-IP) é executado em containers Docker, orquestrados por **Docker Compose** e automatizados com **Ansible**.
-   **Automação e Orquestração:** O script `manage.sh` orquestra todas as etapas: validação, provisionamento da infraestrutura e deploy dos containers.
-   **Gerenciamento de Segredos Robusto:** Credenciais sensíveis, como sua chave SSH pública e a senha do administrador do Foundry, são armazenadas de forma segura no **OCI Vault**.
-   **DNS Dinâmico Opcional:** Integração automatizada com o **No-IP** para hostname fixo (ex: `meu-rpg.ddns.net`).
-   **Instância "Always Free" Otimizada:** Utiliza o shape `VM.Standard.E2.1.Micro` (AMD/x86) para maior disponibilidade na camada gratuita da OCI.

Com este projeto, você tem um servidor de Foundry VTT pronto para uso, com a flexibilidade, portabilidade e segurança dos containers Docker, sem custos inesperados.

## 🛠️ Pré-requisitos

Para utilizar este projeto, certifique-se de ter os seguintes pré-requisitos instalados e configurados em sua máquina local:

1.  **Conta na Oracle Cloud:** Com acesso à camada "Always Free".
2.  **CLI da OCI Instalada e Configurada:**
    -   Siga o [guia oficial](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) para instalar a CLI.
    -   Execute `oci setup config` para configurá-la. O script deste projeto lerá as credenciais diretamente de lá.
3.  **Chave SSH:** Uma chave SSH pública deve existir em `~/.ssh/id_rsa.pub`. Se não tiver, gere com `ssh-keygen -t rsa -b 4096`.
4.  **Software Local:**
    -   [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
    -   [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## 🚨 Solução de Problemas (Permissões na OCI)

Ao interagir com a nuvem, o erro mais comum é o de permissões insuficientes. Se o comando `init` falhar com uma mensagem sobre "NotAuthorizedOrNotFound", significa que seu usuário OCI não tem permissão para gerenciar os recursos necessários (como Vaults, redes e máquinas virtuais).

Para resolver isso, utilize o comando auxiliar para gerar as políticas de permissão exatas para você:

```bash
./manage.sh check-permissions
```

Este comando irá inspecionar sua configuração da OCI, encontrar seu grupo de usuários e imprimir na tela as regras que você precisa adicionar no painel da Oracle em **Identity & Security > Policies**. Ele também fornecerá o comando exato da CLI para criar essas permissões, se você preferir. Após aplicar as permissões, rode o `./manage.sh init` novamente.

## 🚀 Como Usar

O uso foi simplificado para um fluxo de trabalho de três etapas, gerenciado pelo script `manage.sh`.

> **Quer entender os detalhes?**
> Se você é novo em tudo isso e quer entender *como* a mágica funciona, criamos uma **documentação detalhada e amigável para iniciantes** na pasta [`docs/`](./docs/00_POR_ONDE_COMECAR.md). Recomendamos começar por lá!

### 1. Configurar o Projeto

Primeiro, clone o repositório. O projeto é configurado através de arquivos na pasta `config/`.

1.  **Copie os Templates:** Execute o comando `init` para criar a pasta `config` a partir dos templates.
    ```bash
    ./manage.sh init
    ```

2.  **Edite os Arquivos:**
    *   `config/terraform.tfvars`: Preencha com os OCIDs da sua conta OCI (tenancy, user, compartment) e a região.
    *   `config/foundry_vars.yml`: Defina a senha de administrador do Foundry e o domínio (caso utilize).
    *   `config/noip_vars.yml`: Se usar No-IP, adicione suas credenciais e o hostname.
    *   (Opcional) `config/foundry.env`: Para variáveis extras do container Foundry.
    *   (Opcional) `config/noip.conf`: Para configuração avançada do No-IP.
3.  **(Opcional) URL de Download:** Se você possui uma URL de download para o `foundryvtt.zip`, pode criar um arquivo `.env` na raiz do projeto e adicionar:
    ```
    FOUNDRY_DOWNLOAD_URL="SUA_URL_DE_DOWNLOAD_AQUI"
    ```
    Se a URL não for fornecida, coloque o arquivo `foundryvtt.zip` manualmente em `ansible/roles/foundry_vtt/files/`.

### 2. Validar a Configuração (Comando `preflight`)

Este comando é um passo crucial de validação. Ele verifica suas dependências locais (OCI CLI, Terraform, Ansible) e sua configuração. Mais importante, ele se conecta à sua conta OCI para **criar ou sincronizar automaticamente os segredos necessários no OCI Vault**, como a sua chave SSH pública.

```bash
./manage.sh preflight
```

Execute este comando sempre que alterar sua configuração principal.

### 3. Subir o Servidor (Comando `up`)

Com a configuração validada, para criar e provisionar o servidor, execute:

```bash
./manage.sh up
```

O script irá:
-   Executar o **Terraform** para provisionar a infraestrutura (VM, rede, etc.).
-   Executar o **Ansible** para:
    - Instalar Docker e Docker Compose na VM.
    - Gerar e iniciar um `docker-compose.yml` com os containers do **Foundry VTT**, **Caddy** (SSL) e **No-IP**.
-   Ao final, o endereço IP público do seu servidor e as credenciais de acesso ao Foundry VTT serão exibidos.

### 4. Limpeza Completa (Comando `clean` ou `down`)

Para apagar **TUDO** que foi criado por este projeto na sua conta OCI (servidor, rede, Vault, chaves) e os arquivos de configuração locais, execute:

```bash
./manage.sh clean
```

Este comando é **DESTRUTIVO** e exigirá sua confirmação.

## Estrutura do Projeto

```
.
├── ansible/          # Playbooks e roles do Ansible para configurar a VM.
│   └── roles/
│       └── foundry_vtt/
│           ├── tasks/
│           │   └── main.yml      # Tarefas principais: instalar Docker, rodar Docker Compose.
│           └── templates/
│               ├── Caddyfile.j2
│               └── docker-compose.yml.j2 # Template para a stack de containers.
├── config_templates/ # Templates para os arquivos de configuração.
├── scripts/          # Scripts de shell que implementam a lógica dos comandos.
├── terraform/        # Código de infraestrutura do Terraform.
├── .gitignore
├── manage.sh         # Script principal para gerenciar toda a stack.
└── README.md
```