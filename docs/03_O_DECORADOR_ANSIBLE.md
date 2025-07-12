# 03 - O Decorador (Ansible)

Depois que o Terraform (o arquiteto) construiu nosso servidor, o Ansible entra em cena como o **decorador**. Sua função é instalar e configurar todo o software necessário *dentro* do servidor para que o Foundry VTT funcione.

Este projeto usa uma abordagem moderna: em vez de instalar cada programa diretamente no sistema, o Ansible prepara o servidor para rodar **Containers Docker**.

Pense nos containers como "kits de aplicação" autocontidos. Cada serviço (Foundry VTT, Caddy) roda em sua própria caixa isolada, com tudo o que precisa para funcionar, garantindo consistência e evitando conflitos.

## O Livro de Instruções do Decorador (`ansible/playbook.yml`)

O playbook principal do Ansible (`ansible/playbook.yml`) executa uma série de tarefas no servidor recém-criado. As principais etapas são:

1.  **Instalar Dependências Essenciais:** Garante que ferramentas como `ufw` (firewall) e `unzip` estejam presentes.
2.  **Configurar o Firewall:** Abre apenas as portas necessárias para a internet:
    *   **Porta 22:** Para acesso SSH (nossa manutenção).
    *   **Porta 80/443:** Para tráfego web (HTTP/HTTPS), gerenciado pelo Caddy.
3.  **Instalar Docker e Docker Compose:** Prepara o servidor para ser um "anfitrião" de containers. Ele também adiciona o usuário padrão (`ubuntu`) ao grupo do Docker, para que possamos gerenciar os containers sem precisar de `sudo` o tempo todo.
4.  **Preparar e Implantar a Stack de Serviços:**
    *   Cria os diretórios necessários no servidor (ex: `/home/ubuntu/foundry-docker`).
    *   **Gera os arquivos de configuração a partir de templates:**
        *   Usa `ansible/roles/foundry_vtt/templates/docker-compose.yml.j2` para criar o arquivo `/home/ubuntu/foundry-docker/docker-compose.yml` no servidor. Este arquivo é a receita que define quais containers devem rodar (Foundry, Caddy, etc.).
        *   Usa `ansible/roles/foundry_vtt/templates/Caddyfile.j2` para criar o `Caddyfile` no servidor, que configura nosso reverse proxy.
    *   **Inicia os Serviços:** Executa o comando `docker-compose up -d`, que lê o arquivo `docker-compose.yml` gerado e inicia todos os nossos serviços em seus respectivos containers.

Ao final da execução do Ansible, o servidor estará totalmente configurado e pronto para uso, com o Foundry VTT acessível através do endereço IP ou do domínio configurado.

Continue para `04_O_MAESTRO_MANAGE_SH.md`.