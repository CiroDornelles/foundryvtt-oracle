#!/bin/bash

# ==============================================================================
# CAMADA 1: ORQUESTRADOR PRINCIPAL
# Responsabilidade: Ponto de entrada do usuário. Carrega configurações e
# utilitários, analisa o comando do usuário e delega a execução para o
# manipulador (handler) apropriado na Camada 2.
# ==============================================================================

# --- Carregamento e Configuração Inicial ---

# Garante que o script pare em caso de erro, em variáveis não definidas e em erros de pipe.
set -euo pipefail

# Carrega as variáveis de ambiente do arquivo .env, se ele existir.
if [ -f ".env" ]; then
    set -a
    source ".env"
    set +a
fi

# Carrega a camada de utilitários. A verificação de existência é crucial.
if [ -f "scripts/utils.sh" ]; then
    source "scripts/utils.sh"
else
    echo "FATAL: O arquivo de utilitários 'scripts/utils.sh' não foi encontrado."
    exit 1
fi

# --- Roteador de Comandos ---

# O primeiro argumento é o comando principal.
COMMAND="${1-}" # Usa valor padrão para evitar erro com 'set -u' se nenhum argumento for passado

# Se nenhum comando for fornecido, ou se for o comando de ajuda, exibe a ajuda.
if [ -z "$COMMAND" ] || [ "$COMMAND" == "help" ] || [ "$COMMAND" == "--help" ]; then
    source "scripts/help_handler.sh"
    display_help
    exit 0
fi

# O 'case' atua como um roteador, carregando e executando o handler apropriado.
case "$COMMAND" in
    up)
        source "scripts/up_handler.sh"
        run_up
        ;;
    
    down|clean)
        source "scripts/destroy_handler.sh"
        run_destroy
        ;;

    init)
        source "scripts/init_handler.sh"
        if [[ "${2-}" == "--interactive" ]]; then
            run_init_interactive
        elif [[ "${2-}" == "--force" ]]; then
            run_init_declarative "force"
        else
            run_init_declarative
        fi
        ;;

    preflight)
        source "scripts/preflight_handler.sh"
        run_preflight_checks
        ;;

    ssh-server)
        log_step "Conectando ao servidor via SSH..."
        public_ip=$(cd terraform && terraform output -raw instance_public_ip)
        if [ -z "$public_ip" ]; then
            handle_error "Não foi possível obter o IP público. A infraestrutura existe?"
        fi
        ssh "ubuntu@${public_ip}"
        ;;

    status)
        log_step "Verificando o status da infraestrutura com Terraform..."
        cd terraform || handle_error "Diretório 'terraform' não encontrado."
        terraform state list
        cd ..
        ;;

    *)
        log_error "Comando inválido: '$COMMAND'"
        echo -e "Use ${YELLOW}'./manage.sh help'${NC} para ver a lista de comandos disponíveis."
        exit 1
        ;;
esac

exit 0