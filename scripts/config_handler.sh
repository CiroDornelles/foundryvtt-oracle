#!/bin/bash
set -euo pipefail
# scripts/config_handler.sh
# Responsável por gerar e carregar o arquivo de configuração (config.sh).

CONFIG_FILE="config.sh"
OCI_CONFIG_FILE="$HOME/.oci/config"


# Função obsoleta: configuração agora é feita via arquivos em config/ e .tfvars
generate_config_file() {
    log_warn "Função 'generate_config_file' obsoleta. Use arquivos em config/ para variáveis do Terraform."
}

# Carrega o arquivo de configuração, falhando se não existir.
load_config() {
    source "$CONFIG_FILE" || handle_error "Falha ao carregar '$CONFIG_FILE'." "Execute './manage.sh init' primeiro."
}