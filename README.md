# Foundry VTT na Oracle Cloud (IaC)

Este projeto utiliza Terraform e Ansible para provisionar e configurar de forma automatizada um servidor Foundry VTT na camada "Always Free" da Oracle Cloud Infrastructure (OCI).

Com os scripts deste repositório, você pode criar e destruir toda a infraestrutura com comandos simples, facilitando o gerenciamento e evitando custos.

## Visão Geral

- **Infraestrutura como Código (IaC):** A infraestrutura (VM, Rede, IP Público) é definida com **Terraform**.
- **Gerenciamento de Configuração:** A instalação e configuração do software (Node.js, Foundry VTT, Caddy) na VM é feita com **Ansible**.
- **Resultado:** Um servidor Foundry VTT pronto para uso, acessível via IP público ou um nome de domínio com HTTPS.

## Pré-requisitos

Antes de começar, você precisará de:

1.  **Conta na Oracle Cloud:** Com acesso à camada "Always Free".
2.  **Credenciais da API OCI:** Siga o [guia da OCI](https-link-para-guia) para gerar sua chave de API e coletar as informações necessárias (OCIDs de usuário, tenancy, fingerprint).
3.  **URL de Download do Foundry VTT:** Uma URL de download válida e temporária para a versão Linux/Node.js, obtida do seu perfil no [site oficial do Foundry VTT](https://foundryvtt.com/).
4.  **Chave SSH:** Uma chave SSH pública deve estar disponível em `~/.ssh/id_rsa.pub`. Se você não tiver uma, gere-a com o comando `ssh-keygen -t rsa -b 4096`. Esta chave é usada para acessar a VM criada.
5.  **Software Instalado Localmente:**
    *   [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
    *   [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
    *   (Opcional) [CLI da OCI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)

## Como Usar

### 1. Configuração Inicial

Clone este repositório e navegue até o diretório:

```bash
git clone https://github.com/CiroDornelles/foundry-vtt-iac.git
cd foundry-vtt-iac
```

Crie o seu arquivo de configuração a partir do template:

```bash
cp config.template.sh config.sh
```

Edite o arquivo `config.sh` e preencha **todas** as variáveis com suas informações da OCI e do Foundry VTT.

**Opcional (HTTPS com Domínio):** Se você deseja acessar seu servidor via um domínio (ex: `https://foundry.seusite.com`), preencha a variável `ANSIBLE_VAR_foundry_domain_name`. Você **deve** configurar um registro DNS do tipo `A` apontando seu domínio para o IP público que será gerado quando o servidor for criado. O script do Caddy cuidará automaticamente do certificado SSL.

### 2. Subir o Servidor

Para criar e provisionar o servidor, execute:

```bash
./manage.sh up
```

O script irá:
1.  Executar `terraform apply` para criar os recursos na OCI.
2.  Gerar um inventário Ansible com o IP da nova VM.
3.  Executar o `ansible-playbook` para instalar e configurar o Foundry VTT.

Ao final, o endereço IP público do seu servidor será exibido.

### 3. Destruir o Servidor

Para remover completamente todos os recursos da OCI e evitar custos, execute:

```bash
./manage.sh down
```

Este comando executará `terraform destroy`.

## Estrutura do Projeto

```
.
├── ansible/          # Playbooks e roles do Ansible
├── terraform/        # Código de infraestrutura do Terraform
├── .gitignore
├── config.sh         # (Seu arquivo, ignorado pelo Git)
├── config.template.sh
├── manage.sh         # Script principal para subir/descer a stack
└── README.md
```

## Detalhes Técnicos

*(Esta seção será preenchida com mais detalhes sobre as decisões de implementação do Terraform e Ansible conforme avançamos.)*
