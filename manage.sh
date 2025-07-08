#!/bin/bash

set -e # Encerra o script se um comando falhar

# Carrega as variáveis de ambiente do arquivo de configuração
if [ -f "config.sh" ]; then
    source config.sh
else
    echo "Erro: O arquivo de configuração 'config.sh' não foi encontrado."
    echo "Copie 'config.template.sh' para 'config.sh' e preencha as variáveis."
    exit 1
fi

# Navega para o diretório do Terraform
cd terraform

# Função para o comando 'up'
up() {
    # Bloco do Terraform
    (
        cd terraform
        echo "Inicializando o Terraform..."
        terraform init -upgrade
        echo "Criando a infraestrutura na OCI..."
        terraform apply -auto-approve
    )

    # Obter o IP público da saída do Terraform
    PUBLIC_IP=$(cd terraform && terraform output -raw foundry_instance_public_ip)

    if [ -z "$PUBLIC_IP" ]; then
        echo "Erro: Não foi possível obter o IP público da instância."
        exit 1
    fi

    echo "Servidor Foundry VTT está disponível no IP: $PUBLIC_IP"

    # Bloco do Ansible
    (
        cd ansible

        echo "Gerando arquivo de inventário para o Ansible..."
        echo "[foundry_server]" > inventory.ini
        echo "$PUBLIC_IP ansible_user=ubuntu" >> inventory.ini

        echo "Gerando arquivo de variáveis para o Ansible..."
        cat <<EOF > vars.yml
---
foundry_download_url: "$ANSIBLE_VAR_foundry_download_url"
foundry_admin_user: "$ANSIBLE_VAR_foundry_admin_user"
foundry_admin_password: "$ANSIBLE_VAR_foundry_admin_password"
foundry_domain_name: "$ANSIBLE_VAR_foundry_domain_name"
EOF

        echo "Aguardando a instância ficar pronta para SSH..."
        sleep 30 # Dá um tempo para a VM inicializar completamente

        echo "Executando o playbook do Ansible para configurar o servidor..."
        ansible-playbook -i inventory.ini playbook.yml --private-key ~/.ssh/id_rsa
    )

    echo "Configuração do Ansible concluída!"
    echo "Seu servidor Foundry VTT está pronto em http://$PUBLIC_IP:30000"
}

# Função para o comando 'down'
down() {
    (
        cd terraform
        echo "Destruindo a infraestrutura na OCI..."
        terraform destroy -auto-approve
    )
    echo "Infraestrutura destruída com sucesso."
}

# Verifica o comando passado para o script
case "$1" in
    up)
        up
        ;;
    down)
        down
        ;;
    *)
        echo "Uso: $0 {up|down}"
        exit 1
        ;;
esac
