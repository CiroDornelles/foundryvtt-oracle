#!/bin/bash
set -euo pipefail
# ==============================================================================
# CAMADA 2: MANIPULADOR (HANDLER)
# Responsabilidade: Conter a lógica de negócio para os comandos 'down' e 'clean'.
# Orquestra a destruição da infraestrutura e a limpeza de arquivos locais.
# ==============================================================================

# Função principal que executa o processo de destruição e limpeza.
run_destroy() {
    # --- FASE -1: Pré-verificação ---
    source "scripts/preflight_handler.sh"
    run_preflight_checks

    log_step "Iniciando processo de destruição e limpeza..."
    
    # --- FASE 1: Confirmação do Usuário ---
    log_warn "Esta ação é DESTRUTIVA e removerá toda a infraestrutura na OCI e arquivos locais."
    read -p "Digite 'destruir' para confirmar: " confirmation
    
    if [[ "$confirmation" != "destruir" ]]; then
        log_warn "Confirmação inválida. Operação cancelada."
        exit 1
    fi

    # --- FASE 2: Destruição da Infraestrutura ---
    log_step "Destruindo a infraestrutura com Terraform..."
    cd terraform || handle_error "Diretório 'terraform' não encontrado."
    
    if terraform destroy -auto-approve -var-file=../config/terraform.tfvars; then
        log_success "Infraestrutura na OCI destruída com sucesso."
    else
        # Mesmo em caso de falha, tentamos continuar com a limpeza local.
        log_error "Ocorreu um erro ao destruir a infraestrutura com Terraform. Verifique a saída acima."
    fi
    cd ..

    # --- FASE 3: Limpeza de Arquivos Locais ---
    log_step "Limpando arquivos de projeto gerados e configuração..."
    
    rm -f ansible/inventory
    rm -f terraform_apply.log
    rm -f ansible_playbook.log
    rm -f foundry-iac.log
    
    # Limpeza mais profunda dentro dos diretórios das ferramentas
    rm -rf terraform/.terraform*
    rm -f terraform/terraform.tfstate*

    # Remove a pasta de configuração inteira
    rm -rf config
    
    log_success "Limpeza de arquivos locais e configuração concluída."
    echo -e "\n${GREEN}Operação finalizada. O ambiente foi restaurado ao estado inicial.${NC}\n"
}
