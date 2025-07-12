#!/bin/bash
set -euo pipefail
# ==============================================================================
# CAMADA 2: MANIPULADOR (HANDLER)
# Responsabilidade: Conter a lógica de negócio para o comando 'up'.
# Orquestra as ferramentas (Terraform, Ansible) e chama a camada de
# utilitários para fornecer feedback ao usuário.
# ==============================================================================

# Função principal que executa o processo de implantação.
run_up() {
    # --- FASE -1: Pré-verificação ---
    source "scripts/preflight_handler.sh"
    run_preflight_checks

    # --- FASE 0: Inicialização e Plano ---
    source "config/script_config.sh"
    if [[ "$LOG_MODE" == "interactive" ]]; then
        initialize_up_summary
        display_up_summary
    fi

    # --- FASE 1: Provisionamento com Terraform ---
    log_step "Iniciando provisionamento da infraestrutura com Terraform..."
    cd terraform || handle_error "Diretório 'terraform' não encontrado."
    
    local tf_command="terraform apply -auto-approve -var-file=../config/terraform.tfvars"
    if [[ "$LOG_MODE" == "interactive" || "$LOG_MODE" == "file" ]]; then
        eval "$tf_command -no-color" > ../terraform_apply.log 2>&1
    else
        eval "$tf_command"
    fi

    if [ $? -eq 0 ]; then
        log_success "Infraestrutura provisionada com sucesso na OCI."
        [[ "$LOG_MODE" == "interactive" ]] && update_step_status "TF_PROVISION" "done"
    else
        log_error "Falha durante o provisionamento com Terraform."
        [[ "$LOG_MODE" == "interactive" ]] && update_step_status "TF_PROVISION" "fail"
        [[ -f ../terraform_apply.log ]] && cat ../terraform_apply.log
        handle_error "Consulte o log acima para detalhes do erro do Terraform."
    fi
    
    local public_ip
    public_ip=$(terraform output -raw instance_public_ip)
    cd ..

    # --- FASE 2: Configuração com Ansible ---
    log_step "Iniciando configuração do software com Ansible..."
    if [ -z "$public_ip" ]; then
        handle_error "Não foi possível obter o IP público da instância do Terraform."
    fi
    echo "[foundry_server]" > ansible/inventory
    echo "$public_ip ansible_user=ubuntu" >> ansible/inventory

    local ansible_command="ansible-playbook -i ansible/inventory ansible/playbook.yml"
    if [[ "$LOG_MODE" == "interactive" || "$LOG_MODE" == "file" ]]; then
        eval "$ansible_command" > ansible_playbook.log 2>&1
    else
        eval "$ansible_command"
    fi

    if [ $? -eq 0 ]; then
        log_success "Servidor configurado com sucesso via Ansible."
        [[ "$LOG_MODE" == "interactive" ]] && update_step_status "ANSIBLE_CONFIG" "done"
    else
        log_error "Falha durante a configuração com Ansible."
        [[ "$LOG_MODE" == "interactive" ]] && update_step_status "ANSIBLE_CONFIG" "fail"
        [[ -f ansible_playbook.log ]] && cat ansible_playbook.log
        handle_error "Consulte o log acima para detalhes do erro do Ansible."
    fi

    # --- FASE 3: Feedback Final ---
    log_step "Implantação concluída!"
    if [[ "$LOG_MODE" == "interactive" ]]; then
        update_step_status "FINAL_FEEDBACK" "done"
        display_up_summary
    fi

    # Carrega as variáveis de configuração para exibir o feedback
    local domain_name
    domain_name=$(grep 'domain_name:' config/foundry_vars.yml | awk '{print $2}')
    local admin_password
    admin_password=$(grep 'admin_password:' config/foundry_vars.yml | awk '{print $2}')

    if [ -z "$admin_password" ]; then
        admin_password="(Não definida, será solicitada no primeiro acesso)"
    fi

    echo -e "${GREEN}Seu servidor Foundry VTT está pronto!${NC}"
    echo -e "-----------------------------------------------------"
    echo -e "  ${YELLOW}Endereço IP:${NC} ${public_ip}"
    if [ -n "$domain_name" ]; then
        echo -e "  ${YELLOW}Acesse em:${NC}   https://${domain_name}"
    else
        echo -e "  ${YELLOW}Acesse em:${NC}   http://${public_ip}:30000"
    fi
    echo -e "  ${YELLOW}Usuário:${NC}     admin"
    echo -e "  ${YELLOW}Senha:${NC}       ${admin_password}"
    echo -e "-----------------------------------------------------"
    echo -e "  ${BLUE}Para conectar via SSH:${NC} ./manage.sh ssh-bastion"
    echo -e "  ${BLUE}Para destruir tudo:${NC}   ./manage.sh down"
    echo -e "-----------------------------------------------------\n"
}