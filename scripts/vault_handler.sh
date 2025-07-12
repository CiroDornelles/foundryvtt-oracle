#!/bin/bash
set -euo pipefail
# scripts/vault_handler.sh
# Responsável por toda a interação com o OCI Vault.

# Função genérica para esperar um recurso atingir um estado desejado
wait_for_oci_state() {
    local resource_name="$1"
    local get_command="$2"
    local expected_state="$3"
    local max_attempts=60 # 6 minutos (60 * 6s)
    local attempt=0
    log "Aguardando '$resource_name' atingir o estado '$expected_state'..."
    while [ $attempt -lt $max_attempts ]; do
        # Usa o --query nativo da OCI CLI para mais robustez
        local current_state; current_state=$(run_oci $get_command --query 'data."lifecycle-state"' --raw-output)
        if [ "$current_state" == "$expected_state" ]; then
            log_ok "'$resource_name' está '$expected_state'."
            return 0
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 6
    done
    handle_error "Tempo de espera esgotado para '$resource_name' atingir o estado '$expected_state'."
}

# Garante que o Vault e a Chave de Criptografia existam, criando-os se necessário.
# Retorna o OCID do Vault e o OCID da Chave em variáveis globais.
ensure_vault_and_key() {
    local compartment_ocid="$1"
    local vault_name="foundry-vtt-iac-vault"
    local key_name="foundry-vtt-iac-key"
    
    VAULT_OCID=$(run_oci oci kms management vault list --compartment-id "$compartment_ocid" --query "data[?"display-name" == '$vault_name' && "lifecycle-state" == 'ACTIVE'].id | [0]" --raw-output)
    if [ -z "$VAULT_OCID" ] || [ "$VAULT_OCID" == "null" ]; then
        log "Criando novo Vault ($vault_name)..."
        VAULT_OCID=$(run_oci oci kms management vault create --compartment-id "$compartment_ocid" --display-name "$vault_name" --vault-type "DEFAULT" --query 'data.id' --raw-output)
        wait_for_oci_state "Vault" "oci kms management vault get --vault-id $VAULT_OCID" "ACTIVE"
    else
        log_ok "Usando Vault existente."
    fi

    local management_endpoint; management_endpoint=$(run_oci oci kms management vault get --vault-id "$VAULT_OCID" --query 'data."management-endpoint"' --raw-output)
    
    KEY_OCID=$(run_oci oci kms management key list --compartment-id "$compartment_ocid" --endpoint "$management_endpoint" --query "data[?"display-name" == '$key_name' && "lifecycle-state" == 'ENABLED'].id | [0]" --raw-output)
    if [ -z "$KEY_OCID" ] || [ "$KEY_OCID" == "null" ]; then
        log "Criando nova chave de criptografia ($key_name)..."
        KEY_OCID=$(run_oci oci kms management key create --compartment-id "$compartment_ocid" --display-name "$key_name" --key-shape '{"algorithm":"AES","length":"32"}' --protection-mode "SOFTWARE" --endpoint "$management_endpoint" --query 'data.id' --raw-output)
        wait_for_oci_state "Chave" "oci kms management key get --key-id $KEY_OCID --endpoint $management_endpoint" "ENABLED"
    else
        log_ok "Usando chave de criptografia existente."
    fi
}

# Cria ou atualiza um segredo no Vault.
# Retorna o OCID do segredo em uma variável global.
create_or_update_secret() {
    local secret_name="$1"
    local secret_content_b64="$2"
    local compartment_ocid="$3"
    
    local existing_secret_ocid; existing_secret_ocid=$(run_oci oci vault secret list --compartment-id "$compartment_ocid" --vault-id "$VAULT_OCID" --name "$secret_name" --query "data[?"lifecycle-state" == 'ACTIVE'].id | [0]" --raw-output)
    
    if [ -n "$existing_secret_ocid" ] && [ "$existing_secret_ocid" != "null" ]; then
        log "Atualizando segredo: $secret_name"
        # CORREÇÃO: Removido o > /dev/null e a saída é ignorada no nível do comando
        run_oci oci vault secret update-base64 --secret-id "$existing_secret_ocid" --secret-content-content "$secret_content_b64" >/dev/null
        SECRET_OCID="$existing_secret_ocid"
    else
        log "Criando novo segredo: $secret_name"
        # CORREÇÃO: Usando --query em vez de | jq
        SECRET_OCID=$(run_oci oci vault secret create-base64 --compartment-id "$compartment_ocid" --vault-id "$VAULT_OCID" --key-id "$KEY_OCID" --secret-name "$secret_name" --secret-content-content "$secret_content_b64" --query 'data.id' --raw-output)
    fi
    log_ok "Segredo '$secret_name' armazenado."
}

# Recupera o conteúdo de um segredo do Vault.
retrieve_secret() {
    local secret_ocid="$1"
    run_oci oci vault secret get --secret-id "$secret_ocid" --query 'data."secret-content".content' --raw-output | base64 --decode
}
