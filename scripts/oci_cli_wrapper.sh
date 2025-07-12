#!/bin/bash
set -euo pipefail
# scripts/oci_cli_wrapper.sh
# Wrapper seguro para executar comandos da OCI CLI.

# Executa um comando da OCI, capturando e tratando erros de forma robusta.
# Todos os argumentos passados para esta função são tratados como o comando a ser executado.
run_oci() {
    local stderr_file; stderr_file=$(mktemp)
    local output
    
    # Suprime o aviso de permissões de arquivo da OCI CLI que quebra o parse de JSON.
    export SUPPRESS_LABEL_WARNING=True
    
    # Executa o comando diretamente, sem eval, para um redirecionamento de erro mais confiável.
    output=$( ( "$@" ) 2>"$stderr_file" )
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        local error_output; error_output=$(cat "$stderr_file")
        rm "$stderr_file"
        handle_error "Um comando da OCI falhou. A saída do erro foi:\n$error_output" "Execute 'oci setup config' e verifique as permissões da sua conta."
    fi
    
    rm "$stderr_file"
    echo "$output"
}