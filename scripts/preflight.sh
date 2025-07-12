#!/bin/bash
set -euo pipefail
# scripts/preflight.sh
# Responsável por verificar se todas as dependências do sistema estão instaladas.

check_dependencies() {
    log "Verificando dependências..."
    command -v oci >/dev/null || handle_error "Comando 'oci' não encontrado." "https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm"
    command -v terraform >/dev/null || handle_error "Comando 'terraform' não encontrado." "https://learn.hashicorp.com/tutorials/terraform/install-cli"
    command -v ansible >/dev/null || handle_error "Comando 'ansible' não encontrado." "https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html"
    command -v jq >/dev/null || handle_error "Comando 'jq' não encontrado." "sudo apt install jq"
    
    local oci_config_file="$HOME/.oci/config"
    local ssh_public_key_path="$HOME/.ssh/id_rsa.pub"
    
    [ -f "$oci_config_file" ] || handle_error "Arquivo '$oci_config_file' não encontrado." "Execute 'oci setup config'."
    [ -f "$ssh_public_key_path" ] || handle_error "Chave SSH '$ssh_public_key_path' não encontrada." "Execute 'ssh-keygen'."
    
    log_ok "Todas as dependências foram atendidas."
}