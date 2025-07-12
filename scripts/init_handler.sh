#!/bin/bash
set -euo pipefail
# ==============================================================================
# CAMADA 2: MANIPULADOR (HANDLER)
# Responsabilidade: Conter a lógica para inicializar a configuração
# do projeto, suportando tanto o modo declarativo (padrão) quanto
# o interativo (opcional).
# ==============================================================================

# --- Função Principal do Modo Declarativo ---
run_init_declarative() {
    log_step "Inicializando configuração no modo declarativo..."
    
    local force_mode="${1-}" # Default to empty string if not provided

    if [ -d "config" ] && [ "$(ls -A config)" ]; then
        if [[ "$force_mode" == "force" ]]; then
            log_warn "Modo --force ativado. Sobrescrevendo a configuração existente sem confirmação."
        else
            log_warn "A pasta 'config' já existe e não está vazia."
            read -p "Deseja sobrescrever a configuração existente? (s/N): " confirm
            if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
                log_warn "Operação cancelada."
                exit 0
            fi
        fi
        rm -rf config/*
    fi

    # Garante que a pasta exista caso tenha sido limpa ou não existia
    mkdir -p config

    log_success "Copiando templates de configuração para a pasta 'config/'..."
    cp -r config_templates/* config/
    
    # Renomeia os arquivos .template para seus nomes corretos
    for file in config/*.template; do
        mv "$file" "${file%.template}"
    done

    # Cria o arquivo de configuração do script
    echo '# Define o modo de feedback visual do script: "interactive", "simple", "file"' > config/script_config.sh
    echo 'LOG_MODE="interactive"' >> config/script_config.sh

    echo -e "\n${GREEN}Configuração inicial criada em 'config/'.${NC}"
    echo -e "Por favor, edite os arquivos com seus valores e depois execute:"
    echo -e "  ${YELLOW}./manage.sh preflight${NC} para validar sua configuração."
}

# --- Função Principal do Modo Interativo ---
run_init_interactive() {
    log_warn "O modo de inicialização interativo ainda não foi implementado."
    echo "Por favor, use o modo declarativo por enquanto:"
    echo "1. Execute: ./manage.sh init"
    echo "2. Edite os arquivos na pasta 'config/'."
    exit 1
}
