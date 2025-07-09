#!/bin/bash

# --- Variáveis Globais e Arquivos de Configuração ---
CONFIG_FILE="config.sh"
ANSIBLE_VARS_FILE="ansible/vars.yml"
OCI_CONFIG_FILE="$HOME/.oci/config"
SSH_PUBLIC_KEY_PATH="$HOME/.ssh/id_rsa.pub"

# Cores para a saída
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# --- Funções Auxiliares ---

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

log() {
    echo -e "\n${BLUE}>> $1${NC}"
}

log_error() {
    echo -e "${RED}ERRO: $1${NC}"
}

prompt_user() {
    local prompt_text="$1"
    local var_name="$2"
    local default_value="$3"
    local is_secret="${4:-false}"
    local input

    if [ "$is_secret" = true ]; then
        read -sp "$prompt_text" input
        echo
    else
        read -p "$prompt_text" input
    fi
    
    if [ -z "$input" ] && [ -n "$default_value" ]; then
        eval "$var_name=\"$default_value\""
    else
        eval "$var_name=\"$input\""
    fi
}

# Função para executar comandos OCI com tratamento de erro
run_oci() {
    local output
    output=$(eval "$@" 2>&1)
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "Um comando da OCI falhou (código de saída: $exit_code)."
        if [[ "$output" == *"NotAuthorizedOrNotFound"* ]]; then
            echo -e "${YELLOW}Causa provável: Faltam permissões na sua conta OCI.${NC}"
            echo "Seu usuário precisa de permissão para gerenciar 'vaults', 'keys' e 'secrets'."
            echo "Vá para 'Identity & Security' -> 'Policies' no console da OCI e adicione as seguintes regras ao seu grupo de usuários:"
            echo -e "${GREEN}Allow group <SeuGrupo> to manage vaults in tenancy${NC}"
            echo -e "${GREEN}Allow group <SeuGrupo> to manage keys in tenancy${NC}"
            echo -e "${GREEN}Allow group <SeuGrupo> to manage secrets in tenancy${NC}"
        else
            echo "Saída do erro:"
            echo "$output"
        fi
        exit 1
    fi
    echo "$output"
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        return 0
    else
        log_error "Arquivo de configuração '$CONFIG_FILE' não encontrado."
        echo "Por favor, execute o comando './manage.sh init' primeiro."
        return 1
    fi
}

# --- Lógica Principal dos Comandos ---

init() {
    log "Iniciando a configuração interativa do projeto..."

    if ! command_exists oci; then log_error "A CLI da OCI não está instalada ou não está no seu PATH."; exit 1; fi
    if [ ! -f "$OCI_CONFIG_FILE" ]; then log_error "Arquivo de configuração da OCI '$OCI_CONFIG_FILE' não encontrado."; exit 1; fi
    if [ ! -f "$SSH_PUBLIC_KEY_PATH" ]; then log_error "Chave SSH pública não encontrada em '$SSH_PUBLIC_KEY_PATH'."; exit 1; fi

    log "Lendo sua configuração da OCI em '$OCI_CONFIG_FILE'..."
    TF_VAR_tenancy_ocid=$(grep '^tenancy' "$OCI_CONFIG_FILE" | awk -F'=' '{print $2}')
    TF_VAR_user_ocid=$(grep '^user' "$OCI_CONFIG_FILE" | awk -F'=' '{print $2}')
    TF_VAR_fingerprint=$(grep '^fingerprint' "$OCI_CONFIG_FILE" | awk -F'=' '{print $2}')
    TF_VAR_private_key_path=$(grep '^key_file' "$OCI_CONFIG_FILE" | awk -F'=' '{print $2}')
    TF_VAR_region=$(grep '^region' "$OCI_CONFIG_FILE" | awk -F'=' '{print $2}')
    TF_VAR_compartment_ocid=$TF_VAR_tenancy_ocid
    echo "Valores extraídos com sucesso."

    log "Por favor, forneça as seguintes informações:"
    prompt_user "URL de download do Foundry VTT (versão Linux/Node.js): " ANSIBLE_VAR_foundry_download_url
    prompt_user "Senha do administrador do Foundry (deixe em branco para gerar uma aleatória): " ANSIBLE_VAR_foundry_admin_password "" true
    prompt_user "Domínio para o Foundry (ex: foundry.meusite.com, opcional para Caddy): " ANSIBLE_VAR_foundry_domain_name

    ANSIBLE_VAR_noip_hostname=""
    prompt_user "Deseja configurar o DNS dinâmico com No-IP? [s/N]: " setup_noip "n"
    if [[ "$setup_noip" =~ ^[sS](im)?$ ]]; then
        prompt_user "Hostname do No-IP (ex: seu-rpg.ddns.net): " ANSIBLE_VAR_noip_hostname
        prompt_user "Usuário (email) do No-IP: " ANSIBLE_VAR_noip_username
        prompt_user "Senha do No-IP: " ANSIBLE_VAR_noip_password "" true
    fi

    log "Configurando o OCI Vault para armazenar sua chave SSH de forma segura..."
    local vault_name="foundry-vtt-iac-vault"
    local key_name="foundry-vtt-iac-key"
    local secret_name="foundry-vtt-iac-ssh-key"
    
    VAULT_OCID=$(run_oci oci vault vault list --compartment-id "$TF_VAR_compartment_ocid" --display-name "$vault_name" --query "data[0].id" --raw-output)
    if [ -z "$VAULT_OCID" ] || [ "$VAULT_OCID" == "null" ]; then
        echo "Criando um novo Vault ($vault_name)..."
        VAULT_OCID=$(run_oci oci vault vault create --compartment-id "$TF_VAR_compartment_ocid" --vault-type "DEFAULT" --display-name "$vault_name" --query 'data.id' --raw-output)
        run_oci oci vault vault wait-for-state --vault-id "$VAULT_OCID" --state "ACTIVE"
    else
        echo "Usando Vault existente ($vault_name)."
    fi
    
    MANAGEMENT_ENDPOINT=$(run_oci oci vault vault get --vault-id "$VAULT_OCID" --query 'data."management-endpoint"' --raw-output)
    
    KEY_OCID=$(run_oci oci vault key list --compartment-id "$TF_VAR_compartment_ocid" --endpoint "$MANAGEMENT_ENDPOINT" --display-name "$key_name" --query "data[0].id" --raw-output)
    if [ -z "$KEY_OCID" ] || [ "$KEY_OCID" == "null" ]; then
        echo "Criando uma nova chave de criptografia ($key_name)..."
        KEY_OCID=$(run_oci oci vault key create --compartment-id "$TF_VAR_compartment_ocid" --display-name "$key_name" --key-shape '{"algorithm":"AES","length":"32"}' --protection-mode "SOFTWARE" --endpoint "$MANAGEMENT_ENDPOINT" --query 'data.id' --raw-output)
        run_oci oci vault key wait-for-state --key-id "$KEY_OCID" --state "ENABLED" --endpoint "$MANAGEMENT_ENDPOINT"
    else
        echo "Usando chave de criptografia existente ($key_name)."
    fi

    echo "Fazendo upload da sua chave SSH pública para o Vault..."
    TF_VAR_ssh_public_key_secret_ocid=$(run_oci oci vault secret create-base64 --compartment-id "$TF_VAR_compartment_ocid" --vault-id "$VAULT_OCID" --key-id "$KEY_OCID" --secret-name "$secret_name" --secret-content-content-file "$SSH_PUBLIC_KEY_PATH" --query 'data.id' --raw-output)
    echo "Chave SSH armazenada com sucesso no Vault."

    log "Gerando arquivo de configuração '$CONFIG_FILE'..."
    cat > "$CONFIG_FILE" <<EOF
# Arquivo de configuração gerado automaticamente por './manage.sh init'
export TF_VAR_tenancy_ocid="$TF_VAR_tenancy_ocid"
export TF_VAR_user_ocid="$TF_VAR_user_ocid"
export TF_VAR_fingerprint="$TF_VAR_fingerprint"
export TF_VAR_private_key_path="$TF_VAR_private_key_path"
export TF_VAR_region="$TF_VAR_region"
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

    echo -e "${GREEN}--- Configuração Concluída! ---${NC}"
    echo "O arquivo '$CONFIG_FILE' foi criado com sucesso."
    echo "Agora você pode executar './manage.sh up' para subir o servidor."
}

up() {
    if ! load_config; then exit 1; fi
    log "Iniciando o processo de criação da infraestrutura (up)..."
    (
        cd terraform
        log "Inicializando o Terraform..."
        terraform init -upgrade
        log "Aplicando o plano do Terraform para criar os recursos na OCI..."
        terraform apply -auto-approve
    )
    PUBLIC_IP=$(cd terraform && terraform output -raw foundry_instance_public_ip)
    if [ -z "$PUBLIC_IP" ]; then log_error "Não foi possível obter o IP público da instância."; exit 1; fi
    log "IP Público da instância: $PUBLIC_IP"
    (
        cd ansible
        log "Gerando inventário e variáveis para o Ansible..."
        echo "[foundry_server]" > inventory.ini
        echo "$PUBLIC_IP ansible_user=ubuntu" >> inventory.ini
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
        log "Aguardando a instância ficar pronta para conexão SSH (60s)..."
        sleep 60
        log "Executando o playbook do Ansible para configurar o servidor..."
        ansible-playbook -i inventory.ini playbook.yml --private-key ~/.ssh/id_rsa
    )
    echo -e "${GREEN}--- Servidor Pronto! ---${NC}"
    echo "Seu servidor Foundry VTT está pronto para ser acessado."
    if [ -n "$ANSIBLE_VAR_foundry_domain_name" ]; then
        echo "Acesse em: https://$ANSIBLE_VAR_foundry_domain_name"
    elif [ -n "$ANSIBLE_VAR_noip_hostname" ]; then
        echo "Acesse em: http://$ANSIBLE_VAR_noip_hostname:30000"
    else
        echo "Acesse em: http://$PUBLIC_IP:30000"
    fi
}

down() {
    if ! load_config; then exit 1; fi
    log "Iniciando a destruição da infraestrutura do Terraform (down)..."
    (
        cd terraform
        terraform destroy -auto-approve
    )
    log "Infraestrutura do Terraform destruída com sucesso."
}

clean() {
    if ! load_config; then echo -e "${YELLOW}Nenhuma configuração para limpar.${NC}"; exit 0; fi
    log "Iniciando a limpeza completa (clean)..."
    down
    log "Deletando o Secret da chave SSH do Vault..."
    run_oci oci vault secret schedule-deletion --secret-id "$METADATA_SECRET_OCID" --wait-for-state "DELETED"
    log "Deletando o Vault..."
    run_oci oci vault vault schedule-deletion --vault-id "$METADATA_VAULT_OCID" --wait-for-state "DELETED"
    log "Removendo arquivos de configuração locais..."
    rm -f "$CONFIG_FILE" "ansible/inventory.ini" "$ANSIBLE_VARS_FILE"
    rm -rf "terraform/.terraform" "terraform/terraform.tfstate*"
    echo -e "${GREEN}--- Limpeza Concluída! ---${NC}"
}

case "$1" in
    init) init ;;
    up) up ;;
    down) down ;;
    clean) clean ;;
    *)
        echo "Uso: $0 {init|up|down|clean}"
        echo "  ${GREEN}init${NC}  - Configura o projeto de forma interativa."
        echo "  ${GREEN}up${NC}    - Cria e provisiona o servidor Foundry VTT na OCI."
        echo "  ${GREEN}down${NC}  - Destrói a infraestrutura do servidor (VM, Rede, etc)."
        echo "  ${GREEN}clean${NC} - Destrói TUDO, incluindo o Vault e as configurações locais."
        exit 1
        ;;
esac