#!/bin/bash

# --- Variáveis Globais e Arquivos de Configuração ---
CONFIG_FILE="config.sh"
ANSIBLE_VARS_FILE="ansible/vars.yml"
OCI_CONFIG_FILE="$HOME/.oci/config"
SSH_PUBLIC_KEY_PATH="$HOME/.ssh/id_rsa.pub"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# --- Funções de Utilidade ---

log() { echo -e "\n${BLUE}>> $1${NC}"; }
log_ok() { echo -e "${GREEN}✔ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
log_error() { echo -e "${RED}✖ ERRO: $1${NC}"; }

# Função de tratamento de erro centralizada
handle_error() {
    local message="$1"
    local tutorial="$2"
    log_error "$message"
    if [ -n "$tutorial" ]; then
        echo -e "\n${YELLOW}--- Mini-Tutorial: Como Resolver ---${NC}"
        echo -e "$tutorial"
        echo -e "${YELLOW}------------------------------------${NC}"
    fi
    exit 1
}

prompt_user() {
    local prompt_text="$1"
    local var_name="$2"
    local default_value="$3"
    local is_secret="${4:-false}"
    local input
    if [ "$is_secret" = true ]; then read -sp "$prompt_text" input; echo; else read -p "$prompt_text" input; fi
    if [ -z "$input" ] && [ -n "$default_value" ]; then eval "$var_name=\"$default_value\"\"; else eval "$var_name=\"$input\"\"; fi
}

run_oci() {
    local output; output=$(eval "$@" 2>&1); local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        local tutorial="Execute './manage.sh check-permissions' para gerar as políticas de permissão necessárias e siga as instruções."
        if [[ "$output" != *"NotAuthorizedOrNotFound"* ]]; then tutorial="A saída do erro foi:\n$output"; fi
        handle_error "Um comando da OCI falhou." "$tutorial"
    fi
    echo "$output"
}

# --- Funções de Comandos ---

check_prerequisites() {
    log "Verificando pré-requisitos..."
    command -v oci >/dev/null || handle_error "Comando 'oci' não encontrado." "A CLI da OCI é essencial. Siga o guia de instalação oficial em:\nhttps://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm"
    command -v terraform >/dev/null || handle_error "Comando 'terraform' não encontrado." "Terraform é essencial. Siga o guia de instalação oficial em:\nhttps://learn.hashicorp.com/tutorials/terraform/install-cli"
    command -v ansible >/dev/null || handle_error "Comando 'ansible' não encontrado." "Ansible é essencial. Siga o guia de instalação oficial em:\nhttps://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html"
    [ -f "$OCI_CONFIG_FILE" ] || handle_error "Arquivo de configuração da OCI não encontrado." "Execute 'oci setup config' e siga as instruções para criar o arquivo de configuração em '$OCI_CONFIG_FILE'."
    [ -f "$SSH_PUBLIC_KEY_PATH" ] || handle_error "Chave SSH pública não encontrada." "Uma chave SSH é necessária para acesso seguro. Gere uma com o comando:\nssh-keygen -t rsa -b 4096"
    log_ok "Todos os pré-requisitos foram atendidos."
}

check_permissions() {
    check_prerequisites
    log "Verificando permissões e gerando políticas..."
    local user_ocid; user_ocid=$(grep '^user' "$OCI_CONFIG_FILE" | awk -F'=' '{print $2}')
    local tenancy_ocid; tenancy_ocid=$(grep '^tenancy' "$OCI_CONFIG_FILE" | awk -F'=' '{print $2}')
    log "Buscando o grupo do seu usuário (OCID: $user_ocid)..."
    local group_info; group_info=$(oci iam user group-membership list --user-id "$user_ocid" --all 2>/dev/null)
    if [ -z "$group_info" ] || [[ "$group_info" == *"NotAuthorizedOrNotFound"* ]]; then
        handle_error "Não foi possível encontrar um grupo para o seu usuário." "Seu usuário OCI precisa pertencer a um grupo (ex: 'Administrators') para ter permissões.\n1. Acesse o console da OCI: https://cloud.oracle.com\n2. Vá para 'Identity & Security' -> 'Groups'.\n3. Clique no grupo 'Administrators'.\n4. Clique em 'Add User to Group' e adicione seu usuário."
    fi
    local group_name; group_name=$(echo "$group_info" | grep "group-name" | head -n 1 | awk -F'"' '{print $4}')
    log_ok "Usuário encontrado no grupo: $group_name"
    log "Políticas de permissão recomendadas para o grupo '$group_name':"
    local statements="[\"Allow group $group_name to manage vaults in tenancy\", \"Allow group $group_name to manage keys in tenancy\", \"Allow group $group_name to manage secrets in tenancy\", \"Allow group $group_name to manage virtual-network-family in tenancy\", \"Allow group $group_name to manage instance-family in tenancy\"]"
    echo -e "${YELLOW}${statements//\"/\\\"}${NC}"
    log "Para criar uma política com essas permissões, você pode:"
    echo "1. ${BLUE}Via Console Web:${NC} Vá para 'Identity & Security' -> 'Policies', clique em 'Create Policy' e cole as linhas amarelas."
    echo "2. ${BLUE}Via CLI:${NC} Copie e cole o comando abaixo:"
    echo -e "${GREEN}oci iam policy create --compartment-id \"$tenancy_ocid\" --name \"FoundryIAC-Permissions\" --description \"Permissões para o projeto Foundry VTT IaC\" --statements '$statements'${NC}"
}

init() {
    check_prerequisites
    log "Iniciando a configuração interativa do projeto..."
    local TF_VAR_tenancy_ocid; TF_VAR_tenancy_ocid=$(grep '^tenancy' "$OCI_CONFIG_FILE" | awk -F'=' '{print $2}')
    local TF_VAR_compartment_ocid=$TF_VAR_tenancy_ocid
    log "Por favor, forneça as seguintes informações:"
    prompt_user "URL de download do Foundry VTT (versão Linux/Node.js): " ANSIBLE_VAR_foundry_download_url
    prompt_user "Senha do administrador do Foundry (deixe em branco para aleatória): " ANSIBLE_VAR_foundry_admin_password "" true
    prompt_user "Domínio para o Foundry (ex: foundry.meusite.com, opcional): " ANSIBLE_VAR_foundry_domain_name
    local ANSIBLE_VAR_noip_hostname=""; prompt_user "Deseja configurar o DNS dinâmico com No-IP? [s/N]: " setup_noip "n"
    if [[ "$setup_noip" =~ ^[sS](im)?$ ]]; then
        prompt_user "Hostname do No-IP (ex: seu-rpg.ddns.net): " ANSIBLE_VAR_noip_hostname
        prompt_user "Usuário (email) do No-IP: " ANSIBLE_VAR_noip_username
        prompt_user "Senha do No-IP: " ANSIBLE_VAR_noip_password "" true
    fi
    log "Configurando o OCI Vault..."
    local vault_name="foundry-vtt-iac-vault"; local key_name="foundry-vtt-iac-key"; local secret_name="foundry-vtt-iac-ssh-key"
    local VAULT_OCID; VAULT_OCID=$(run_oci oci vault vault list --compartment-id "$TF_VAR_compartment_ocid" --display-name "$vault_name" --query "data[0].id" --raw-output)
    if [ -z "$VAULT_OCID" ] || [ "$VAULT_OCID" == "null" ]; then
        log "Criando um novo Vault ($vault_name)..."
        VAULT_OCID=$(run_oci oci vault vault create --compartment-id "$TF_VAR_compartment_ocid" --vault-type "DEFAULT" --display-name "$vault_name" --query 'data.id' --raw-output)
        run_oci oci vault vault wait-for-state --vault-id "$VAULT_OCID" --state "ACTIVE"
    else
        log_ok "Usando Vault existente."
    fi
    local MANAGEMENT_ENDPOINT; MANAGEMENT_ENDPOINT=$(run_oci oci vault vault get --vault-id "$VAULT_OCID" --query 'data."management-endpoint"' --raw-output)
    local KEY_OCID; KEY_OCID=$(run_oci oci vault key list --compartment-id "$TF_VAR_compartment_ocid" --endpoint "$MANAGEMENT_ENDPOINT" --display-name "$key_name" --query "data[0].id" --raw-output)
    if [ -z "$KEY_OCID" ] || [ "$KEY_OCID" == "null" ]; then
        log "Criando nova chave de criptografia ($key_name)..."
        KEY_OCID=$(run_oci oci vault key create --compartment-id "$TF_VAR_compartment_ocid" --display-name "$key_name" --key-shape '{"algorithm":"AES","length":"32"}' --protection-mode "SOFTWARE" --endpoint "$MANAGEMENT_ENDPOINT" --query 'data.id' --raw-output)
        run_oci oci vault key wait-for-state --key-id "$KEY_OCID" --state "ENABLED" --endpoint "$MANAGEMENT_ENDPOINT"
    else
        log_ok "Usando chave de criptografia existente."
    fi
    log "Fazendo upload da chave SSH pública para o Vault..."
    local TF_VAR_ssh_public_key_secret_ocid; TF_VAR_ssh_public_key_secret_ocid=$(run_oci oci vault secret create-base64 --compartment-id "$TF_VAR_compartment_ocid" --vault-id "$VAULT_OCID" --key-id "$KEY_OCID" --secret-name "$secret_name" --secret-content-content-file "$SSH_PUBLIC_KEY_PATH" --query 'data.id' --raw-output)
    log_ok "Chave SSH armazenada com segurança no Vault."
    log "Gerando arquivo de configuração '$CONFIG_FILE'..."
    grep -v "ANSIBLE_VAR_noip" "$OCI_CONFIG_FILE" > "$CONFIG_FILE" # Start with OCI config
    cat >> "$CONFIG_FILE" <<EOF
export TF_VAR_compartment_ocid="$TF_VAR_compartment_ocid"
export TF_VAR_ssh_public_key_secret_ocid="$TF_VAR_ssh_public_key_secret_ocid"
export ANSIBLE_VAR_foundry_download_url="$ANSIBLE_VAR_foundry_download_url"
export ANSIBLE_VAR_foundry_admin_user="admin"
export ANSIBLE_VAR_foundry_admin_password="$ANSIBLE_VAR_foundry_admin_password"
export ANSIBLE_VAR_foundry_domain_name="$ANSIBLE_VAR_foundry_domain_name"
export ANSIBLE_VAR_noip_hostname="$ANSIBLE_VAR_noip_hostname"
export ANSIBLE_VAR_noip_username="$ANSIBLE_VAR_noip_username"
export ANSIBLE_VAR_noip_password="$ANSIBLE_VAR_noip_password"
export METADATA_VAULT_OCID="$VAULT_OCID"
export METADATA_SECRET_OCID="$TF_VAR_ssh_public_key_secret_ocid"
EOF
    log_ok "Configuração concluída! Execute './manage.sh up' para subir o servidor."
}

up() {
    source "$CONFIG_FILE" || handle_error "Falha ao carregar '$CONFIG_FILE'." "Execute './manage.sh init' primeiro para gerar o arquivo de configuração."
    log "Iniciando o processo de criação da infraestrutura (up)..."
    (cd terraform && terraform init -upgrade && terraform apply -auto-approve) || handle_error "O Terraform encontrou um erro." "Verifique a saída acima para detalhes. Pode ser um limite da sua conta OCI ou um erro de configuração."
    local PUBLIC_IP; PUBLIC_IP=$(cd terraform && terraform output -raw foundry_instance_public_ip)
    [ -n "$PUBLIC_IP" ] || handle_error "Não foi possível obter o IP público da instância." "Verifique os 'outputs' do Terraform."
    log_ok "IP Público da instância: $PUBLIC_IP"
    log "Gerando inventário e variáveis para o Ansible..."
    echo "[foundry_server]" > ansible/inventory.ini; echo "$PUBLIC_IP ansible_user=ubuntu" >> ansible/inventory.ini
    cat > "$ANSIBLE_VARS_FILE" <<EOF
---
foundry_download_url: "$ANSIBLE_VAR_foundry_download_url"
foundry_admin_user: "$ANSIBLE_VAR_foundry_admin_user"
foundry_admin_password: "$ANSIBLE_VAR_foundry_admin_password"
foundry_domain_name: "$ANSIBLE_VAR_foundry_domain_name"
noip_hostname: "$ANSIBLE_VAR_noip_hostname"
noip_username: "$ANSIBLE_VAR_noip_username"
noip_password: "$ANSIBLE_VAR_noip_password"
EOF
    log "Aguardando conexão SSH com o servidor..."
    for i in {1..15}; do ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -q ubuntu@$PUBLIC_IP exit && break; echo -n "."; sleep 10; done
    if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -q ubuntu@$PUBLIC_IP exit; then
        handle_error "Não foi possível conectar ao servidor via SSH." "Verifique as regras de segurança (porta 22) no console da OCI e sua conexão de rede."
    fi
    log_ok "Conexão SSH estabelecida."
    log "Executando o playbook do Ansible..."
    (cd ansible && ansible-playbook -i inventory.ini playbook.yml --private-key ~/.ssh/id_rsa) || handle_error "O Ansible encontrou um erro." "Verifique a saída acima. Causas comuns:\n- URL de download do Foundry inválida/expirada.\n- Credenciais do No-IP incorretas.\n- Problemas de rede."
    log_ok "Servidor pronto!"
    local access_url="http://$PUBLIC_IP:30000"
    if [ -n "$ANSIBLE_VAR_foundry_domain_name" ]; then access_url="https://$ANSIBLE_VAR_foundry_domain_name"; fi
    if [ -n "$ANSIBLE_VAR_noip_hostname" ] && [ -z "$ANSIBLE_VAR_foundry_domain_name" ]; then access_url="http://$ANSIBLE_VAR_noip_hostname:30000"; fi
    echo "Acesse em: $access_url"
}

down() {
    source "$CONFIG_FILE" || handle_error "Falha ao carregar '$CONFIG_FILE'."
    log "Iniciando a destruição da infraestrutura do Terraform..."
    (cd terraform && terraform destroy -auto-approve) || handle_error "O Terraform encontrou um erro ao destruir a infraestrutura."
    log_ok "Infraestrutura do Terraform destruída."
}

clean() {
    if [ ! -f "$CONFIG_FILE" ]; then log_warn "Nenhuma configuração para limpar."; exit 0; fi
    log "Iniciando a limpeza completa..."
    down
    source "$CONFIG_FILE"
    log "Agendando exclusão do Secret e do Vault..."
    run_oci oci vault secret schedule-deletion --secret-id "$METADATA_SECRET_OCID" --wait-for-state "DELETED"
    run_oci oci vault vault schedule-deletion --vault-id "$METADATA_VAULT_OCID" --wait-for-state "DELETED"
    log "Removendo arquivos de configuração locais..."
    rm -f "$CONFIG_FILE" "ansible/inventory.ini" "$ANSIBLE_VARS_FILE"
    rm -rf "terraform/.terraform" "terraform/terraform.tfstate*"
    log_ok "Limpeza completa!"
}

# --- Ponto de Entrada ---
case "$1" in
    init|up|down|clean|check-permissions) "$1" ;;
    *)
        echo "Uso: $0 {init|up|down|clean|check-permissions}"
        echo "  ${GREEN}init${NC}               - Configura o projeto de forma interativa."
        echo "  ${GREEN}up${NC}                 - Cria e provisiona o servidor Foundry VTT na OCI."
        echo "  ${GREEN}down${NC}               - Destrói a infraestrutura do servidor (VM, Rede, etc)."
        echo "  ${GREEN}clean${NC}              - Destrói TUDO, incluindo o Vault e as configurações locais."
        echo "  ${GREEN}check-permissions${NC}  - Gera as políticas de permissão da OCI necessárias para o projeto."
        exit 1
        ;;
esac