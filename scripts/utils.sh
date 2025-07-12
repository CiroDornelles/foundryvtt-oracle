#!/bin/bash
set -euo pipefail
# ==============================================================================
# CAMADA 3: UTILITÁRIOS
# Responsabilidade: Fornecer funções genéricas e um sistema de log
# configurável para todo o projeto. A forma como o feedback é exibido
# é decidida aqui, com base na variável LOG_MODE.
# ==============================================================================

# --- Configuração de Cores e Log ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

LOG_FILE="foundry-iac.log"

# --- Funções de Logging (Interface Pública para as outras camadas) ---

# Usado para mensagens de log gerais e informativas.
log() {
    echo -e "${BLUE}>> $1${NC}"
}

# Usado para anunciar o início de uma etapa principal.
log_step() {
    local message="$1"
    case "${LOG_MODE-}" in
        interactive)
            echo -e "\n${BLUE}==> $message${NC}"
            ;;
        simple|file)
            echo -e "\n${BLUE}>> $message${NC}"
            ;;
    esac
    
    if [[ "${LOG_MODE-}" == "file" ]]; then
        echo "==> $message" >> "$LOG_FILE"
    fi
}

# Usado para feedback de sucesso de uma operação.
log_success() {
    local message="$1"
    case "${LOG_MODE-}" in
        interactive|simple)
            echo -e "${GREEN}✔ $message${NC}"
            ;;
        file)
            echo "✔ $message"
            echo "[SUCCESS] $message" >> "$LOG_FILE"
            ;;
    esac
}

# Usado para avisos.
log_warn() {
    local message="$1"
    case "${LOG_MODE-}" in
        interactive|simple)
            echo -e "${YELLOW}⚠ $message${NC}"
            ;;
        file)
            echo "⚠ $message"
            echo "[WARN] $message" >> "$LOG_FILE"
            ;;
    esac
}

# Usado para reportar erros fatais.
log_error() {
    local message="$1"
    case "${LOG_MODE-}" in
        interactive|simple)
            echo -e "${RED}✖ ERRO: $message${NC}"
            ;;
        file)
            echo "✖ ERRO: $message"
            echo "[ERROR] $message" >> "$LOG_FILE"
            ;;
    esac
}

# Função unificada para lidar com erros e sair.
handle_error() {
    log_error "$1"
    if [[ "${LOG_MODE-}" == "interactive" && -n "${UP_SUMMARY_DEFINED-}" ]]; then
        display_up_summary
    fi
    exit 1
}

# Exporta as funções para que fiquem disponíveis em sub-scripts
export -f log log_step log_success log_warn log_error handle_error

# --- Funções Específicas do Modo Interativo ---

initialize_up_summary() {
    if [[ "${LOG_MODE-}" == "file" ]]; then > "$LOG_FILE"; fi
    export TF_PROVISION="pending"
    export ANSIBLE_CONFIG="pending"
    export FINAL_FEEDBACK="pending"
    export UP_SUMMARY_DEFINED=true
}

update_step_status() {
    export $1=$2
}

_display_summary_step() {
    local status="$1"
    local description="$2"
    case "$status" in
        pending) echo -e "  ${YELLOW}⏳  [Pendente]${NC}  ${description}" ;;
        done) echo -e "  ${GREEN}✅  [Concluído]${NC}  ${description}" ;;
        fail) echo -e "  ${RED}❌  [Falhou]${NC}    ${description}" ;;
    esac
}

display_up_summary() {
    echo -e "\n-----------------------------------------------------"
    echo -e "${BLUE} Relatório de Implantação do Servidor Foundry VTT${NC}"
    echo -e "-----------------------------------------------------"
    _display_summary_step "$TF_PROVISION" "Provisionar Infraestrutura na OCI com Terraform"
    _display_summary_step "$ANSIBLE_CONFIG" "Configurar Software na VM com Ansible"
    _display_summary_step "$FINAL_FEEDBACK" "Exibir Informações de Acesso"
    echo -e "-----------------------------------------------------\n"
}

export -f initialize_up_summary update_step_status _display_summary_step display_up_summary

# --- Função de Fallback ---

function try_or_fallback() {
    local primary_cmd="$1"
    local fallback_cmd="$2"
    shift 2 # Remove os dois primeiros argumentos (comandos) de $@

    log "Tentando comando primário: '${primary_cmd}'..."

    # Tenta o comando primário
    if "${primary_cmd}" "$@"; then
        log_success "Comando primário ('${primary_cmd}') executado com sucesso."
        return 0 # Sucesso
    else
        log_warn "Comando primário ('${primary_cmd}') falhou. Tentando fallback: '${fallback_cmd}'..."
        
        # Tenta o comando de fallback
        if "${fallback_cmd}" "$@"; then
            log_success "Comando de fallback ('${fallback_cmd}') executado com sucesso."
            return 0 # Sucesso via fallback
        else
            log_error "Ambos os comandos ('${primary_cmd}' e '${fallback_cmd}') falharam."
            return 1 # Falha de ambos
        fi
    fi
}

export -f try_or_fallback