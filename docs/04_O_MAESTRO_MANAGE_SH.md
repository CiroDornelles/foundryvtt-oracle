# 04 - O Maestro (`manage.sh`)

Chegamos à peça final do quebra-cabeça: o arquivo `manage.sh`.

Se o Terraform é o arquiteto e o Ansible é o decorador, o `manage.sh` é o **maestro da orquestra**, ou, numa analogia mais simples, o **controle remoto universal** da nossa "fábrica de servidores".

É um arquivo de script. Pense nele como uma lista de atalhos. Em vez de você ter que digitar os comandos longos e complexos do Terraform e do Ansible, nós os programamos dentro deste arquivo em "botões" fáceis de usar.

Vamos ver o que cada botão do nosso controle remoto faz.

---

### Botão 1: `./manage.sh init` (A Configuração Inicial)

-   **O que ele faz?** Este é o primeiro comando que você deve executar, e apenas uma vez. Ele prepara todo o projeto para você.
-   **Nos Bastidores:**
    1.  **Verifica as Ferramentas:** Ele primeiro olha se você tem a "CLI da OCI" (a ferramenta para conversar com a Oracle) e uma "Chave SSH" (a chave da sua casa). Se não tiver, ele avisa.
    2.  **Lê Suas Credenciais:** Ele abre o arquivo de configuração da CLI da OCI (`~/.oci/config`) e pega suas informações de acesso, como um crachá de funcionário.
    3.  **Conversa com Você:** Ele te faz as duas únicas perguntas cujas respostas ele não consegue adivinhar: a URL de download do Foundry e a senha que você quer para o admin.
    4.  **Cria o Cofre:** Ele usa a CLI da OCI para criar um "Vault" (cofre) e uma "Chave de Criptografia" na sua conta Oracle.
    5.  **Guarda a Chave:** Ele pega sua chave SSH pública do seu computador, sobe para a Oracle e a tranca dentro do cofre que acabou de criar.
    6.  **Gera o `config.sh`:** Ele cria um novo arquivo chamado `config.sh` e escreve nele todas as informações que coletou: suas credenciais, a localização do cofre, a URL do Foundry, etc. Este arquivo será a "cola" que une o Terraform e o Ansible.

-   **Analogia:** O `init` é o **gerente de projetos**. Ele faz a primeira reunião, anota todos os requisitos, organiza as ferramentas, cria um local seguro para guardar as chaves e deixa tudo preparado para o início da obra.

---

### Botão 2: `./manage.sh up` (Construir o Servidor)

-   **O que ele faz?** Este comando constrói e configura o servidor do início ao fim.
-   **Nos Bastidores:**
    1.  **Chama o Arquiteto:** Ele executa o comando `terraform apply`. O Terraform lê a "planta da casa" (`main.tf`) e constrói toda a infraestrutura na Oracle Cloud.
    2.  **Pega o Endereço:** Após a construção, o Terraform informa o endereço IP do novo servidor. O `manage.sh` anota esse endereço.
    3.  **Chama o Decorador:** Ele executa o comando `ansible-playbook`. Ele entrega ao Ansible o endereço do servidor e o "livro de instruções" (`playbook.yml`). O Ansible usa a chave SSH para entrar no servidor e instalar tudo.
    4.  **Anuncia o Resultado:** No final, ele te mostra o endereço final para você acessar o Foundry.

-   **Analogia:** Apertar `up` é dar a ordem para **iniciar a produção**. O gerente (manage.sh) primeiro chama o arquiteto (Terraform) para construir a casa e depois chama o decorador (Ansible) para mobiliá-la.

---

### Botão 3: `./manage.sh down` (Demolir o Servidor)

-   **O que ele faz?** Destrói a infraestrutura do servidor (a VM, a rede, o IP), mas **mantém as configurações e o cofre intactos**.
-   **Nos Bastidores:**
    1.  **Chama o Arquiteto para Demolir:** Ele executa o comando `terraform destroy`. O Terraform lê seu estado atual e destrói, um por um, todos os recursos que ele criou na nuvem.

-   **Analogia:** É o botão de **"fim de festa"**. A casa é demolida para não ocupar espaço no terreno (e não gerar custos), mas a planta da casa (`main.tf`) e o cofre com a chave (`OCI Vault`) são mantidos, caso você queira dar outra festa e construir tudo de novo amanhã.

---

### Bot��o 4: `./manage.sh clean` (Limpeza Total)

-   **O que ele faz?** Apaga **TUDO**. O servidor, o cofre, a chave guardada, os arquivos de configuração... tudo. Deixa sua conta da Oracle e sua pasta local como se o projeto nunca tivesse existido.
-   **Nos Bastidores:**
    1.  **Executa o `down`:** Primeiro, ele demole a infraestrutura do servidor, como no comando anterior.
    2.  **Esvazia e Demole o Cofre:** Ele envia comandos para a Oracle para agendar a exclusão da chave SSH de dentro do cofre e, em seguida, agendar a exclusão do próprio cofre.
    3.  **Limpa os Arquivos Locais:** Ele apaga o `config.sh` e outros arquivos temporários que foram criados.

-   **Analogia:** É o botão de **"vender o terreno e queimar a planta da casa"**. É uma limpeza definitiva, para quando você tem certeza de que não usará mais este projeto.

---

E assim, o `manage.sh` orquestra todo o trabalho complexo, permitindo que qualquer pessoa gerencie um servidor poderoso com comandos simples e diretos.
