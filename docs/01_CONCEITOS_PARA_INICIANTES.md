# 01 - Conceitos para Iniciantes (Nosso Dicionário)

Bem-vindo ao nosso dicionário! Antes de olharmos para qualquer código, vamos entender os termos que você verá por aí. Usaremos analogias simples para ajudar.

---

### Computação em Nuvem (A "Nuvem")

-   **O que é?** É simplesmente usar o computador de outra pessoa (ou empresa). Em vez de ter uma máquina física na sua casa, você aluga tempo e espaço em computadores superpotentes que ficam em prédios gigantes e seguros (chamados *Data Centers*) de empresas como a Oracle, Amazon ou Google.
-   **Analogia:** É como usar um serviço de streaming (Netflix) em vez de ter uma prateleira cheia de DVDs em casa. O filme não está no seu aparelho, mas você pode assisti-lo quando quiser. A "Nuvem" é a prateleira de DVDs da Netflix.

---

### Servidor ou Máquina Virtual (VM)

-   **O que é?** É o "computador" que alugamos na nuvem. Ele não é uma máquina física inteira, mas uma fatia de um computador muito potente que se comporta como se fosse um computador independente, com seu próprio sistema operacional (no nosso caso, o Ubuntu, uma versão de Linux), memória e armazenamento.
-   **Analogia:** Se o Data Center da Oracle é um prédio de apartamentos gigante, uma Máquina Virtual é um dos apartamentos. Você aluga um apartamento e pode fazer o que quiser dentro dele, mas o prédio é compartilhado com outros "inquilinos".

---

### Endereço IP

-   **O que é?** É o endereço do nosso servidor na internet. É uma sequência de números (ex: `129.146.213.87`) que permite que outros computadores encontrem e se comuniquem com o nosso.
-   **Analogia:** É exatamente como o endereço da sua casa (Rua, Número, CEP). Para alguém te enviar uma carta (ou para um jogador se conectar ao seu servidor), ele precisa saber o endereço exato.

---

### Infraestrutura como Código (IaC)

-   **O que é?** É a prática de escrever as instruções para construir nosso servidor em arquivos de texto, como uma receita. Em vez de clicar em botões num site para criar uma máquina, nós escrevemos um "roteiro" que descreve exatamente o que queremos.
-   **Analogia:** É a diferença entre cozinhar seguindo a intuição e cozinhar seguindo uma receita detalhada. Com a receita (`código`), qualquer pessoa pode fazer o mesmo bolo (`servidor`) e obter o mesmo resultado, sempre.

---

### Terraform (O Arquiteto)

-   **O que é?** É a ferramenta que usamos para fazer "Infraestrutura como Código". Ele lê nossos arquivos de configuração (a "planta baixa") e se comunica com a Oracle para construir a infraestrutura (o "prédio").
-   **Analogia:** O Terraform é o **arquiteto ou mestre de obras**. Você entrega a ele a planta da casa (`arquivos .tf`), e ele se encarrega de contratar os pedreiros (a Oracle) e garantir que a casa seja construída exatamente como na planta.

---

### Ansible (O Decorador)

-   **O que é?** É outra ferramenta de automação. Depois que o Terraform constrói o servidor (a "casa"), o Ansible entra em ação para instalar e configurar os programas *dentro* dele.
-   **Analogia:** Se o Terraform é o arquiteto que constrói a casa, o Ansible é o **designer de interiores e a equipe de mudança**. Ele entra na casa vazia, pinta as paredes, monta os móveis, instala a geladeira e a TV (no nosso caso, instala o Node.js, o Foundry VTT, o Caddy, etc.) e deixa tudo pronto para morar.

---

### Chave SSH (A Chave da Casa)

-   **O que é?** É um método de acesso muito seguro para "entrar" no nosso servidor e dar comandos a ele. Ela funciona com um par de chaves: uma **pública** (que você pode dar para todo mundo, como um cadeado) e uma **privada** (que só você tem, a chave que abre o cadeado).
-   **Analogia:** A chave pública é o **cadeado** que instalamos na porta do nosso servidor. A chave privada é a **única chave física** que abre esse cadeado. O Ansible usa essa chave para entrar no servidor e arrumar as coisas.

---

### OCI Vault (O Cofre de Chaves)

-   **O que é?** É um serviço da Oracle para guardar informações sensíveis, como senhas ou chaves. Nós o usamos para guardar nossa chave SSH pública.
-   **Analogia:** Em vez de deixar a planta da casa com a localização do cofre e a chave do lado de fora, nós guardamos a chave pública (o cadeado) em um **cofre de verdade** (o Vault). O Terraform (arquiteto) tem permissão para pegar o cadeado no cofre e instalá-lo na porta da casa nova, sem que ninguém mais precise tocar na chave. É muito mais seguro.

---

### `manage.sh` (O Controle Remoto)

-   **O que é?** É um arquivo que criamos para juntar todos os comandos complicados do Terraform e do Ansible em botões simples.
-   **Analogia:** É o **controle remoto da nossa "fábrica de servidores"**. Em vez de ir até a fábrica e operar cada máquina (Terraform, Ansible) individualmente, você só precisa apertar os botões no controle: `init` (Ligar a fábrica), `up` (Construir um servidor), `down` (Demolir o servidor), `clean` (Desligar a fábrica e limpar o terreno).

---

Com estes conceitos em mente, os próximos documentos sobre o código ficarão muito mais claros! Continue para `02_O_ARQUITETO_TERRAFORM.md`.
