# 00 - Por Onde Começar? Uma Introdução ao Projeto

Olá!

Se você está lendo isso, provavelmente faz parte da nossa comunidade de RPG e quer entender como nosso servidor de Foundry VTT funciona "por debaixo dos panos". Talvez o Ciro não esteja por perto e algo precise ser feito, ou talvez você seja apenas uma pessoa curiosa. Seja qual for o motivo, seja bem-vindo!

Este conjunto de documentos foi criado pensando em você: uma pessoa que **não precisa ter nenhum conhecimento de programação ou de "coisas de computador"** para entender o que está acontecendo aqui.

## O Problema que Estamos Resolvendo

Para jogar Foundry VTT online com nossos amigos, precisamos de um "computador" que fique ligado na internet 24 horas por dia para hospedar nosso mundo de jogo. Esse computador é o que chamamos de **servidor**.

Manter um computador em casa ligado o tempo todo gasta energia, exige uma boa internet e pode ser complicado. Além disso, configurar o programa do Foundry para funcionar como um servidor pode ser um processo chato e repetitivo.

## A Solução Mágica Deste Projeto

Este projeto é como uma **receita de bolo mágica e automatizada** para criar nosso servidor de Foundry.

Em vez de comprarmos um computador físico, nós "alugamos" um pedacinho de um computador superpotente de uma empresa chamada Oracle. A isso, damos o nome de **computação em nuvem**. A grande vantagem é que a Oracle tem uma oferta "sempre gratuita" que é perfeita para nós.

O problema é que, mesmo alugando esse computador na nuvem, ainda precisaríamos entrar nele e instalar tudo manualmente... toda vez. Seria um trabalho repetitivo e fácil de cometer erros.

É aí que a mágica acontece: os arquivos neste repositório contêm **instruções exatas e detalhadas** para que os computadores da Oracle:
1.  Construam um servidor para nós do zero.
2.  Instalem e configurem o Foundry VTT nele.
3.  Deixem tudo pronto para jogar.

E o mais importante: podemos **criar e destruir** esse servidor com comandos muito simples, garantindo que nunca vamos pagar nada por acidente.

## Como Ler Esta Documentação

Pense nesta pasta `docs` como um pequeno livro. Sugerimos que você leia na ordem para que tudo faça sentido:

1.  **`01_CONCEITOS_PARA_INICIANTES.md`**: Comece por aqui! É o nosso dicionário. Ele vai te explicar de forma simples o que são os termos técnicos que usamos, como "Nuvem", "Servidor", "IP", "Terraform" e "Ansible".

2.  **`02_O_ARQUITETO_TERRAFORM.md`**: Aqui, vamos explorar a "planta da casa". O Terraform é a ferramenta que diz à Oracle *como* construir nosso servidor, a rede, a segurança, etc.

3.  **`03_O_DECORADOR_ANSIBLE.md`**: Depois que a casa está construída, o Ansible entra para "mobiliar e decorar". Ele instala o Foundry VTT e o deixa prontinho para uso.

4.  **`04_O_MAESTRO_MANAGE_SH.md`**: Este é o nosso "controle remoto". O arquivo `manage.sh` é o único com o qual interagimos, e este documento explica o que cada botão (`init`, `up`, `down`, `clean`) faz.

Nosso objetivo é que, ao final da leitura, você se sinta confortável para, no mínimo, entender como tudo se encaixa. E quem sabe, até se aventurar a executar os comandos!

Vamos começar? Vá para o arquivo `01_CONCEITOS_PARA_INICIANTES.md`.
