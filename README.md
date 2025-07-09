# Foundry VTT na Oracle Cloud (IaC)

Este projeto utiliza Terraform e Ansible para provisionar e configurar de forma totalmente automatizada um servidor Foundry VTT na camada "Always Free" da Oracle Cloud Infrastructure (OCI).

Com um único script, você pode inicializar, criar, destruir e limpar toda a infraestrutura, tornando o processo extremamente simples e à prova de erros.

## Visão Geral

- **Infraestrutura como Código (IaC):** A infraestrutura (VM, Rede, IP Público) é definida com **Terraform**.
- **Gerenciamento de Configuração:** A instalação do software (Node.js, Foundry VTT, Caddy) é feita com **Ansible**.
- **Automação Total:** O script `manage.sh` orquestra todo o processo, desde a configuração inicial até a destruição completa dos recursos.
- **Gerenciamento de Segredos:** As chaves SSH são armazenadas de forma segura no **OCI Vault**, eliminando a necessidade de gerenciá-las localmente.

## Pré-requisitos

1.  **Conta na Oracle Cloud:** Com acesso à camada "Always Free".
2.  **CLI da OCI Instalada e Configurada:**
    -   Siga o [guia oficial](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) para instalar a CLI.
    -   Execute `oci setup config` para configurá-la. O script deste projeto lerá as credenciais diretamente de lá.
3.  **Chave SSH:** Uma chave SSH deve existir em `~/.ssh/id_rsa.pub`. Se não tiver, gere com `ssh-keygen -t rsa -b 4096`.
4.  **Software Local:**
    -   [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
    -   [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Como Usar

O uso foi simplificado para apenas alguns comandos no script `manage.sh`.

> **Quer entender os detalhes?**
> Se você é novo em tudo isso e quer entender *como* a mágica funciona, criamos uma **documentação detalhada e amigável para iniciantes** na pasta [`docs/`](./docs/00_POR_ONDE_COMECAR.md). Recomendamos começar por lá!

### 1. Inicialização (Comando `init`)

Este é o **primeiro e único passo de configuração manual**. Clone o repositório, entre na pasta e execute:

```bash
git clone https://github.com/CiroDornelles/foundry-vtt-iac.git
cd foundry-vtt-iac
./manage.sh init
```

O script irá:
- Validar seus pré-requisitos (CLI da OCI, chave SSH).
- Ler suas credenciais da OCI.
- **Perguntar interativamente** pela URL de download do Foundry VTT e uma senha de admin.
- Criar um Vault na sua conta OCI para guardar sua chave SSH pública de forma segura.
- Gerar um arquivo `config.sh` com todas as informações necessárias.

### 2. Subir o Servidor (Comando `up`)

Com a inicialização feita, para criar e provisionar o servidor, execute:

```bash
./manage.sh up
```

O script irá executar o Terraform e o Ansible. Ao final, o endereço do seu servidor será exibido.

### 3. Destruir o Servidor (Comando `down`)

Para remover a infraestrutura do servidor (VM, IP, etc.) mas **manter o Vault e a configuração**, execute:

```bash
./manage.sh down
```

Isso é útil se você planeja subir o servidor novamente mais tarde.

### 4. Limpeza Completa (Comando `clean`)

Para apagar **TUDO** que foi criado por este projeto, incluindo o servidor, o Vault com a chave SSH e os arquivos de configuração locais, execute:

```bash
./manage.sh clean
```

Isso deixará sua conta OCI e seu diretório local como estavam antes de você começar.

## Estrutura do Projeto

```
.
├── ansible/          # Playbooks e roles do Ansible
├── terraform/        # Código de infraestrutura do Terraform
├── .gitignore
├── manage.sh         # Script principal para gerenciar toda a stack
└── README.md
```