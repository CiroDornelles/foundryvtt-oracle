#!/bin/bash
set -euo pipefail
# scripts/terraform_handler.sh
# Responsável por interagir com o Terraform.

# Executa 'terraform apply' com retentativas.
terraform_apply() {
    log "Iniciando criação da infraestrutura (Terraform)..."
    
    local max_retries=5
    local attempt=1
    local success=false
    while [ $attempt -le $max_retries ]; do
        log "Tentativa $attempt de $max_retries para aplicar o Terraform..."
        if (cd terraform && terraform init -upgrade && terraform apply -auto-approve); then
            success=true
            break
        fi
        log_warn "A tentativa $attempt falhou. O Terraform encontrou um erro."
        if [ $attempt -lt $max_retries ]; then
            local sleep_time=60
            log "Aguardando ${sleep_time}s para a próxima tentativa..."
            sleep $sleep_time
        fi
        attempt=$((attempt + 1))
    done

    if [ "$success" != true ]; then
        handle_error "O Terraform falhou após $max_retries tentativas."
    fi
}

# Executa 'terraform destroy'.
terraform_destroy() {
    log "Iniciando a destruição da infraestrutura (Terraform)..."
    (cd terraform && terraform destroy -auto-approve)
}

# Obtém uma saída (output) do Terraform.
get_terraform_output() {
    local output_name="$1"
    cd terraform && terraform output -raw "$output_name"
}