#!/bin/bash

# -----------------------------------------------------------------------------
# Variáveis de Autenticação da Oracle Cloud Infrastructure (OCI)
# Preencha com as informações da sua conta OCI.
# -----------------------------------------------------------------------------

# O OCID da sua tenancy. Encontre em: Perfil -> Tenancy.
export TF_VAR_tenancy_ocid="SEU_TENANCY_OCID"

# O OCID do seu usuário. Encontre em: Perfil -> User Settings.
export TF_VAR_user_ocid="SEU_USER_OCID"

# O fingerprint da sua chave de API. Encontre em: Perfil -> User Settings -> API Keys.
export TF_VAR_fingerprint="SEU_FINGERPRINT_DA_CHAVE_API"

# O caminho completo para a sua chave privada da API OCI.
# Exemplo: /home/ciro/.oci/oci_api_key.pem
export TF_VAR_private_key_path="CAMINHO_PARA_SUA_CHAVE_PRIVADA_OCI"

# A região da OCI onde a infraestrutura será criada.
# Exemplo: us-ashburn-1
export TF_VAR_region="SUA_REGIAO_OCI"

# -----------------------------------------------------------------------------
# Variáveis de Configuração da Instância e do Foundry VTT
# -----------------------------------------------------------------------------

# O OCID do compartimento onde os recursos serão criados.
# Pode ser o mesmo que o da tenancy (compartimento raiz) ou um compartimento específico.
export TF_VAR_compartment_ocid="SEU_COMPARTMENT_OCID"

# A URL de download temporária para a versão Linux/Node.js do Foundry VTT.
# Obtenha no seu perfil no site oficial: https://foundryvtt.com/
export ANSIBLE_VAR_foundry_download_url="SUA_URL_DE_DOWNLOAD_DO_FOUNDRY"

# (Opcional) O nome de usuário para o administrador do Foundry VTT.
export ANSIBLE_VAR_foundry_admin_user="admin"

# (Opcional) A senha para o administrador do Foundry VTT.
# Se deixar em branco, uma senha aleatória será gerada.
export ANSIBLE_VAR_foundry_admin_password=""

# (Opcional) O nome do seu domínio para acessar o Foundry (ex: foundry.meudominio.com).
# Se preenchido, o Ansible tentará configurar o Caddy com HTTPS.
# Você precisa ter o DNS deste domínio apontando para o IP público do servidor.
export ANSIBLE_VAR_foundry_domain_name=""
