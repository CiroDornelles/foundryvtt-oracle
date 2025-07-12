#!/bin/bash
set -euo pipefail
# ==============================================================================
# CAMADA 2: MANIPULADOR (HANDLER)
# Responsabilidade: Orquestrar a validação da configuração do projeto e
# garantir que os pré-requisitos na nuvem existam, fornecendo feedback
# visual detalhado ao usuário.
# ==============================================================================

# ------------------------------------------------------------------------------
# Seção 1: Funções de Lógica de Negócio (Encapsuladas)
# ------------------------------------------------------------------------------

# Valida a existência e o preenchimento dos arquivos de configuração.
_validate_config_files() {
    local config_files=("config/terraform.tfvars" "config/foundry_vars.yml" "config/noip_vars.yml")
    local all_files_present=true

    for file_path in "${config_files[@]}"; do
        log "Verificando arquivo: ${file_path}..."
        if [ ! -f "${file_path}" ]; then
            log_error "Arquivo não encontrado: ${file_path}"
            echo "Execute './manage.sh init' para criá-lo."
            all_files_present=false
        fi
    done

    if [ "$all_files_present" = false ]; then
        return 1
    fi

    # Agora que sabemos que todos os arquivos existem, validamos o conteúdo de terraform.tfvars
    local tf_vars=("tenancy_ocid" "user_ocid" "fingerprint" "private_key_path" "region" "compartment_ocid")
    log "Validando conteúdo de config/terraform.tfvars..."
    for var in "${tf_vars[@]}"; do
        if grep -q -E "SEU_|CAMINHO_|OCID_" <(grep "^${var}" "config/terraform.tfvars" 2>/dev/null); then
            log_error "A variável '${var}' em 'config/terraform.tfvars' ainda contém um valor padrão."
            return 1
        fi
    done
    return 0
}

# Valida a instalação das dependências de linha de comando.
_validate_local_dependencies() {
    if ! command -v oci &> /dev/null || ! command -v terraform &> /dev/null || ! command -v ansible-playbook &> /dev/null; then
        log_error "Uma ou mais dependências (oci, terraform, ansible) não foram encontradas no seu PATH."
        return 1
    fi
    if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
        log_error "Chave SSH pública não encontrada em ~/.ssh/id_rsa.pub. Por favor, gere uma com 'ssh-keygen'."
        return 1
    fi
    return 0
}

# Orquestra a sincronização de todos os recursos do OCI Vault.
_sync_oci_vault_resources() {
    local compartment_ocid
    compartment_ocid=$(grep 'compartment_ocid' config/terraform.tfvars | awk -F'=' '{print $2}' | tr -d ' ")
    
    # Delega cada etapa para uma função específica e atualiza o status
    _ensure_vault_exists "$compartment_ocid" && update_step_status "PF_VAULT_CHECK" "done" || { update_step_status "PF_VAULT_CHECK" "fail"; return 1; }
    display_preflight_summary
    
    _ensure_key_exists "$compartment_ocid" && update_step_status "PF_KEY_CHECK" "done" || { update_step_status "PF_KEY_CHECK" "fail"; return 1; }
    display_preflight_summary

    _sync_ssh_secret "$compartment_ocid" && update_step_status "PF_SECRET_CHECK" "done" || { update_step_status "PF_SECRET_CHECK" "fail"; return 1; }
    display_preflight_summary

    _update_tfvars_file && update_step_status "PF_TFVARS_UPDATE" "done" || { update_step_status "PF_TFVARS_UPDATE" "fail"; return 1; }
    display_preflight_summary
}

# Garante que o Vault exista, criando-o se necessário.
_ensure_vault_exists() {
    local compartment_ocid="$1"
    local vault_name="foundry-vtt-iac-vault"
    
    # A variável global VAULT_OCID será usada pelas funções subsequentes
    VAULT_OCID=$(oci kms vault list -c "$compartment_ocid" --display-name "$vault_name" --query "data[?"lifecycle-state"=='ACTIVE'].id | [0]" --raw-output 2>/dev/null)
    if [ -z "$VAULT_OCID" ]; then
        log_warn "Nenhum Vault encontrado. Criando um novo..."
        VAULT_OCID=$(oci kms vault create -c "$compartment_ocid" --display-name "$vault_name" --vault-type "DEFAULT" --query "data.id" --raw-output)
        sleep 10 # Aguarda a propagação do recurso
    fi
    [ -n "$VAULT_OCID" ]
}

# Garante que a Chave de Criptografia exista, criando-a se necessário.
_ensure_key_exists() {
    local compartment_ocid="$1"
    local key_name="foundry-vtt-iac-key"
    
    # A variável global KEY_OCID será usada pelas funções subsequentes
    KEY_OCID=$(oci kms key list -c "$compartment_ocid" --display-name "$key_name" --query "data[?"lifecycle-state"=='ENABLED'].id | [0]" --raw-output 2>/dev/null)
    if [ -z "$KEY_OCID" ]; then
        log_warn "Nenhuma Chave encontrada. Criando uma nova..."
        local vault_endpoint
        vault_endpoint=$(oci kms vault get --vault-id "$VAULT_OCID" --query "data.\"management-endpoint\"" --raw-output)
        KEY_OCID=$(oci kms key create -c "$compartment_ocid" --display-name "$key_name" --key-shape '{"algorithm":"AES","length":"32"}' --endpoint "$vault_endpoint" --query "data.id" --raw-output)
        sleep 5
    fi
    [ -n "$KEY_OCID" ]
}

# Sincroniza o conteúdo da chave SSH local com o segredo na OCI.
_sync_ssh_secret() {
    local compartment_ocid="$1"
    local secret_name="foundry-vtt-ssh-public-key"
    
    local ssh_key_b64
    ssh_key_b64=$(base64 < "$HOME/.ssh/id_rsa.pub")
    
    # A variável global SECRET_OCID será usada pela função de atualização do tfvars
    SECRET_OCID=$(oci vault secret list -c "$compartment_ocid" --display-name "$secret_name" --query "data[?"lifecycle-state"=='ACTIVE'].id | [0]" --raw-output 2>/dev/null)

    if [ -z "$SECRET_OCID" ]; then
        log_warn "Nenhum Segredo encontrado. Criando um novo..."
        SECRET_OCID=$(oci vault secret create-base64 -c "$compartment_ocid" --secret-name "$secret_name" --vault-id "$VAULT_OCID" --key-id "$KEY_OCID" --secret-content-content "$ssh_key_b64" --query "data.id" --raw-output)
    else
        oci vault secret update-base64 --secret-id "$SECRET_OCID" --secret-content-content "$ssh_key_b64" > /dev/null
    fi
    [ -n "$SECRET_OCID" ]
}

# Atualiza o arquivo terraform.tfvars com o OCID do segredo.
_update_tfvars_file() {
    if grep -q "ssh_public_key_secret_ocid" "config/terraform.tfvars"; then
        sed -i "s|ssh_public_key_secret_ocid.*|ssh_public_key_secret_ocid = \"$SECRET_OCID\"|g" "config/terraform.tfvars"
    else
        echo -e "\nssh_public_key_secret_ocid = \"$SECRET_OCID\"" >> "config/terraform.tfvars"
    fi
}

# ------------------------------------------------------------------------------
# Seção 2: Funções de Feedback Visual
# ------------------------------------------------------------------------------

initialize_preflight_summary() {
    export LOG_MODE="interactive"
    export UP_SUMMARY_DEFINED=true 

    export PF_CONFIG_VALIDATION="pending"
    export PF_DEPS_VALIDATION="pending"
    export PF_VAULT_CHECK="pending"
    export PF_KEY_CHECK="pending"
    export PF_SECRET_CHECK="pending"
    export PF_TFVARS_UPDATE="pending"
}

display_preflight_summary() {
    clear # Limpa a tela para uma exibição mais limpa
    echo -e "\n-----------------------------------------------------"
    echo -e "${BLUE} Relatório de Verificação de Pré-Requisitos${NC}"
    echo -e "-----------------------------------------------------"
    _display_summary_step "$PF_CONFIG_VALIDATION" "Validar arquivos de configuração"
    _display_summary_step "$PF_DEPS_VALIDATION" "Validar dependências e chave SSH"
    _display_summary_step "$PF_VAULT_CHECK" "Verificar/Criar OCI Vault"
    _display_summary_step "$PF_KEY_CHECK" "Verificar/Criar Chave de Criptografia"
    _display_summary_step "$PF_SECRET_CHECK" "Verificar/Sincronizar Segredo da Chave SSH"
    _display_summary_step "$PF_TFVARS_UPDATE" "Atualizar 'terraform.tfvars' com o OCID do segredo"
    echo -e "-----------------------------------------------------\n"
}

# ------------------------------------------------------------------------------
# Seção 3: Orquestrador Principal
# ------------------------------------------------------------------------------

run_preflight_checks() {
    initialize_preflight_summary
    display_preflight_summary

    if ! _validate_config_files; then
        update_step_status "PF_CONFIG_VALIDATION" "fail"
        handle_error "Validação dos arquivos de configuração falhou."
    fi
    update_step_status "PF_CONFIG_VALIDATION" "done"
    display_preflight_summary

    if ! _validate_local_dependencies; then
        update_step_status "PF_DEPS_VALIDATION" "fail"
        handle_error "Validação de dependências locais falhou."
    fi
    update_step_status "PF_DEPS_VALIDATION" "done"
    display_preflight_summary

    if ! _sync_oci_vault_resources; then
        # A própria função _sync_oci_vault_resources já atualiza os status de falha
        handle_error "Sincronização de recursos na OCI falhou."
    fi
    
    echo -e "${GREEN}Verificação de pré-requisitos concluída com sucesso!${NC}"
}