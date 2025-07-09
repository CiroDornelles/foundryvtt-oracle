# 03 - O Decorador (Ansible)

A casa está construída, mas está vazia. É hora de chamar o **decorador e a equipe de mudança (Ansible)** para deixar tudo pronto para a nossa primeira sessão de RPG.

Ansible funciona com um "livro de instruções" chamado **Playbook**. Nosso playbook principal é o arquivo `ansible/playbook.yml`. Ele é escrito em um formato chamado YAML, que é fácil de ler para humanos.

### O Livro de Instruções (`playbook.yml`)

```yaml
---
- name: Configurar servidor Foundry VTT
  hosts: foundry_server
  become: yes
  vars_files:
    - vars.yml
  roles:
    - role: foundry_vtt
```

-   `name`: O nome da peça, "Configurar servidor Foundry VTT".
-   `hosts`: Diz ao Ansible em qual servidor ele deve trabalhar. `foundry_server` é o apelido que demos ao nosso servidor no inventário que o `manage.sh` cria.
-   `become: yes`: Isso é muito importante. Significa "torne-se o super-usuário (root)".
    -   **Analogia:** É como dar ao decorador a **chave mestra** do prédio, para que ele possa fazer qualquer alteração necessária sem pedir permissão a cada passo.
-   `vars_files`: Diz ao Ansible para carregar um arquivo com "variáveis" (informações que podem mudar), como a URL de download do Foundry e a sua senha.
-   `roles`: A parte principal. Em vez de colocar todas as instruções aqui, nós as organizamos em "funções" (Roles). Aqui, estamos dizendo: "Execute todas as tarefas que estão dentro da função `foundry_vtt`".

### As Tarefas (`ansible/roles/foundry_vtt/tasks/main.yml`)

Este arquivo é a lista de tarefas do nosso decorador. Vamos ver as mais importantes:

---
- `name: Atualizar o cache de pacotes APT`
- `name: Instalar dependências necessárias`

-   **O que fazem?** A primeira tarefa atualiza a "lista de programas disponíveis" do servidor. A segunda instala programas básicos que o Foundry precisa para funcionar, como `nodejs` e `unzip`.
-   **Analogia:** Antes de montar os móveis, a equipe de mudança verifica se tem as ferramentas certas (chave de fenda, martelo) na maleta.

---
- `name: Baixar e descompactar o Foundry VTT`

-   **O que faz?** Esta é uma das tarefas principais. Ela usa a URL que você forneceu no comando `init` para baixar o arquivo do Foundry diretamente da internet e descompactá-lo na pasta `/opt/foundryvtt`.
-   **Analogia:** A equipe de mudança está desembalando a caixa principal: o sofá (nosso software Foundry VTT).

---
- `name: Criar o serviço systemd para o Foundry VTT`
- `name: Habilitar e iniciar o serviço Foundry VTT`

-   **O que fazem?** A primeira tarefa usa um "template" (um modelo de arquivo) para criar um serviço. Um serviço é uma forma de dizer ao sistema operacional para manter um programa rodando o tempo todo, mesmo que a gente se desconecte do servidor. A segunda tarefa ativa e inicia esse serviço.
-   **Analogia:** Isso é como programar a cafeteira para passar café toda manhã automaticamente. Estamos dizendo ao servidor: "Sempre que você ligar, por favor, inicie o programa do Foundry VTT automaticamente".

---
- `name: Instalar o Caddy`
- `name: Configurar o Caddyfile`

-   **O que fazem?** Estas tarefas só são executadas se você forneceu um nome de domínio (ex: `foundry.meusite.com`) durante o `init`. Caddy é um servidor web moderno.
-   **Analogia:** Caddy é o **jardineiro e paisagista**. Em vez de acessar nossa casa por um endereço numérico feio (`http://129.146.213.87:30000`), o Caddy cria um belo caminho no jardim e coloca uma placa com um endereço amigável (`https://foundry.meusite.com`). Ele também cuida do "cadeado de segurança" (HTTPS), tornando a conexão segura. A tarefa `Configurar o Caddyfile` usa outro template para escrever as regras para o Caddy.

---

Ao final da execução do Ansible, nossa casa (servidor) não está mais vazia. Ela está totalmente mobiliada, com o Foundry VTT instalado, configurado e rodando automaticamente, pronto para receber os jogadores.

Agora que entendemos o arquiteto (Terraform) и o decorador (Ansible), vamos ver como o nosso "controle remoto" gerencia tudo isso.

Continue para `04_O_MAESTRO_MANAGE_SH.md`.
