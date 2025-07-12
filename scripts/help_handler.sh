#!/bin/bash
set -euo pipefail
# ==============================================================================
# CAMADA 2: MANIPULADOR (HANDLER)
# Responsabilidade: Conter e exibir a mensagem de ajuda detalhada,
# explicando o propósito de cada comando disponível no orquestrador.
# ==============================================================================

# Função principal que exibe a ajuda.
display_help() {
    echo -e "\n${BLUE}Orquestrador de Implantação para Servidor Foundry VTT${NC}"
    echo -e "-----------------------------------------------------"
    echo -e "Uso: ${YELLOW}./manage.sh [comando]${NC}"
    echo -e "\n${BLUE}Comandos Disponíveis:${NC}\n"

    echo -e "  ${YELLOW}up${NC}"
    echo -e "    Provisiona a infraestrutura na OCI (Terraform) e configura o servidor"
    echo -e "    com Docker e Docker Compose (Ansible). É o comando principal para criar"
    echo -e "    e implantar seu servidor com Foundry VTT, Caddy e No-IP em containers.\n"

    echo -e "  ${YELLOW}down / clean${NC}"
    echo -e "    ${RED}Ação destrutiva.${NC} Destrói toda a infraestrutura criada na OCI"
    echo -e "    e limpa todos os arquivos de estado e logs locais. Pede"
    echo -e "    confirmação antes de executar.\n"

    echo -e "  ${YELLOW}ssh-bastion${NC}"
    echo -e "    Conecta você diretamente ao servidor Foundry VTT via SSH,"
    echo -e "    se a infraestrutura estiver ativa.\n"

    echo -e "  ${YELLOW}status${NC}"
    echo -e "    Verifica e lista o estado atual dos recursos gerenciados"
    echo -e "    pelo Terraform na nuvem.\n"
    
    echo -e "  ${YELLOW}help / --help${NC}"
    echo -e "    Exibe esta mensagem de ajuda.\n"

    echo -e "  ${YELLOW}init${NC}"
    echo -e "    Cria a pasta 'config/' a partir dos templates. Use a flag"
    echo -e "    ${YELLOW}--force${NC} para sobrescrever uma configuração existente sem"
    echo -e "    confirmação interativa.\n"

    echo -e "  ${YELLOW}preflight${NC}"
    echo -e "    ${YELLOW}(Em desenvolvimento)${NC} Verificará as dependências e"
    echo -e "    configurações antes de uma implantação completa.\n"
    
    echo -e "-----------------------------------------------------\n"
}