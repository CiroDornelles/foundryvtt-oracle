# 04 - O Maestro (`manage.sh`)

Chegamos à peça final do quebra-cabeça: o arquivo `manage.sh`.

Se o Terraform é o arquiteto e o Ansible é o decorador, o `manage.sh` é o **maestro da orquestra**, ou, numa analogia mais simples, o **controle remoto universal** da nossa "fábrica de servidores".

É um arquivo de script que criamos para juntar todos os comandos complicados do Terraform e do Ansible em "botões" fáceis de usar.

Vamos ver o que cada botão do nosso controle remoto faz.

---

### Botão 1: `./manage.sh init` (A Configuração Inicial)

-   **O que ele faz?** Este é o primeiro comando que você deve executar. Ele prepara o ambiente de configuração do projeto.
-   **Nos Bastidores:**
    1.  Cria uma pasta chamada `config/`.
    2.  Copia os arquivos de modelo de `config_templates/` para dentro da pasta `config/`.
    3.  Renomeia os arquivos, removendo a extensão `.template`.
-   **Como usar:** Após rodar `init`, você deve editar os arquivos dentro da pasta `config/` com suas próprias informações (credenciais da OCI, configurações do Foundry, etc.).
-   **Flag `--force`:** Se você já tiver uma pasta `config` e quiser começar do zero, pode usar `./manage.sh init --force` para sobrescrevê-la.

---

### Botão 2: `./manage.sh preflight` (A Checagem de Pré-Voo)

-   **O que ele faz?** Antes de tentar subir o servidor, este comando verifica se tudo está configurado corretamente.
-   **Nos Bastidores:**
    1.  **Valida Dependências Locais:** Confere se você tem as ferramentas `oci`, `terraform` e `ansible` instaladas.
    2.  **Valida Arquivos de Configuração:** Garante que os arquivos em `config/` existem e que os valores padrão (como "SEU_OCID_AQUI") foram substituídos.
    3.  **Sincroniza Recursos de Segurança (Vault):** Verifica se um OCI Vault, uma Chave de Criptografia e um Segredo para sua chave SSH existem na sua conta Oracle. Se não existirem, **ele os cria automaticamente**. Ele também atualiza o arquivo `config/terraform.tfvars` com o ID do segredo criado.

---

### Botão 3: `./manage.sh up` (Construir o Servidor)

-   **O que ele faz?** Este comando constrói e configura o servidor do início ao fim.
-   **Nos Bastidores:**
    1.  **Executa a Checagem de Pré-Voo (`preflight`)** para garantir que tudo está pronto.
    2.  **Chama o Arquiteto (Terraform):** Executa `terraform apply`, que lê a "planta da casa" (`terraform/main.tf`) e constrói toda a infraestrutura na Oracle Cloud.
    3.  **Pega o Endereço:** Após a construção, o Terraform informa o endereço IP do novo servidor.
    4.  **Chama o Decorador (Ansible):** Executa `ansible-playbook`. O Ansible usa a chave SSH para entrar no servidor, gera os arquivos de configuração a partir dos templates (`.j2`) e sobe os containers do Foundry VTT e Caddy com o Docker Compose.
    5.  **Anuncia o Resultado:** No final, ele te mostra o endereço final para você acessar o Foundry e as credenciais do admin.

---

### Botão 4: `./manage.sh down` (Destruir o Servidor)

-   **O que ele faz?** Apaga **TUDO** que foi criado por este projeto na sua conta OCI (servidor, rede, etc.) e limpa os arquivos de configuração locais.
-   **Nos Bastidores:**
    1.  **Pede Confirmação:** Por ser uma ação destrutiva, ele exige que você digite "destruir" para continuar.
    2.  **Chama o Arquiteto para Demolir:** Executa `terraform destroy`, que remove todos os recursos criados na nuvem.
    3.  **Limpa os Arquivos Locais:** Apaga a pasta `config/` e outros arquivos de estado e logs gerados.

---

### Comandos Auxiliares

-   `./manage.sh ssh-server`: Conecta você diretamente ao servidor via SSH, se ele estiver ativo.
-   `./manage.sh status`: Mostra o estado atual dos recursos gerenciados pelo Terraform.
-   `./manage.sh help`: Exibe a lista de todos os comandos disponíveis.

E assim, o `manage.sh` orquestra todo o trabalho complexo, permitindo que qualquer pessoa gerencie um servidor poderoso com comandos simples e diretos.