#!/bin/bash
set -euo pipefail
# scripts/ansible_handler.sh
# Responsável por preparar e executar o Ansible.

ANSIBLE_VARS_FILE="ansible/vars.yml"
ANSIBLE_INVENTORY_FILE="ansible/inventory"

# Gera o arquivo de inventário para o Ansible.
generate_ansible_inventory() {
    local public_ip="$1"
    log "Gerando inventário do Ansible..."
    echo "[foundry_server]" > "$ANSIBLE_INVENTORY_FILE"
    echo "$public_ip ansible_user=ubuntu" >> "$ANSIBLE_INVENTORY_FILE"
    log_ok "Inventário gerado em '$ANSIBLE_INVENTORY_FILE'."
}

# Gera o arquivo de variáveis para o Ansible.
generate_ansible_vars() {
    log "Gerando arquivo de variáveis do Ansible..."
    
    # Argumentos passados para a função
    local admin_password="$1"
    local noip_hostname="$2"
    local noip_username="$3"
    local noip_password="$4"
    
    cat > "$ANSIBLE_VARS_FILE" <<EOF
---
foundry_admin_user: "admin"
foundry_admin_password: "$admin_password"
foundry_domain_name: ""
noip_hostname: "$noip_hostname"
noip_username: "$noip_username"
noip_password: "$noip_password"
EOF
    log_ok "Variáveis geradas em '$ANSIBLE_VARS_FILE'."
}

# Espera até que a conexão SSH com o servidor esteja disponível.
wait_for_ssh() {
    local public_ip="$1"
    log "Aguardando conexão SSH com $public_ip (até 5 min)...";
    for i in {1..30}; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes -q "ubuntu@$public_ip" exit; then
            log_ok "Conexão SSH estabelecida."
            return 0
        fi
        echo -n "."
        sleep 10
    done
    handle_error "Não foi possível conectar ao servidor via SSH após várias tentativas."
}

run_ansible_playbook() {
    local ansible_cmd="(cd ansible && ansible-playbook -i inventory playbook.yml --private-key ~/.ssh/id_rsa)"
    if ! run_with_spinner "Executando o playbook do Ansible (esta etapa pode levar vários minutos)..." "$ansible_cmd"; then
        handle_error "O Ansible encontrou um erro."
    fi
}