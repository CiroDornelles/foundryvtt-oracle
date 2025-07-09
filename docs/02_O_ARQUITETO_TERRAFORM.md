# 02 - O Arquiteto (Terraform)

Bem-vindo à planta baixa do nosso projeto!

Este documento vai te guiar pelo arquivo `terraform/main.tf`. Lembre-se da nossa analogia: o Terraform é o **arquiteto**, e este arquivo é a **planta da casa** que ele usa para construir nosso servidor.

O arquivo é lido de cima para baixo. Vamos analisar cada bloco de construção (chamados de "recursos").

### Entendendo a Sintaxe

Quase tudo no Terraform segue este formato:

```hcl
tipo_do_bloco "tipo_do_recurso" "nome_local" {
    parametro1 = "valor"
    parametro2 = "outro_valor"
}
```

-   **`tipo_do_bloco`**: Geralmente é `resource` (algo que o Terraform vai criar e gerenciar) ou `data` (algo que o Terraform vai apenas ler/consultar).
-   **`"tipo_do_recurso"`**: O nome oficial do que queremos criar na Oracle. Por exemplo, `oci_core_vcn` é uma Rede de Nuvem Virtual da Oracle.
-   **`"nome_local"`**: Um apelido que damos ao recurso para podermos nos referir a ele em outras partes do arquivo. Ex: `foundry_vcn`.
-   **`parametro = "valor"`**: As características específicas do recurso. Se fosse uma parede, os parâmetros seriam `altura = "3m"` e `cor = "branco"`.

---

### A Planta Baixa (`main.tf`) Dissecada

#### Bloco 1 e 2: Buscando a Chave SSH no Cofre (`data`)

```hcl
data "oci_vault_secret" "ssh_public_key" { ... }
data "oci_vault_secret_content" "ssh_public_key_content" { ... }
```

-   **O que faz?** Estes blocos não criam nada. Eles são do tipo `data`, o que significa que eles **buscam informações que já existem**. Eles usam o OCID (a "identidade") do nosso segredo, que o script `init` guardou, para ir até o OCI Vault (nosso cofre) e pegar o conteúdo da nossa chave SSH pública.
-   **Por que precisamos disso?** Para que possamos instalar a "fechadura" (a chave pública) na porta do nosso servidor mais tarde, permitindo que o Ansible entre para fazer a configuração.

#### Bloco 3: A Rede Virtual (`oci_core_vcn`)

```hcl
resource "oci_core_vcn" "foundry_vcn" { ... }
```

-   **O que faz?** Cria uma **V**irtual **C**loud **N**etwork (Rede de Nuvem Virtual).
-   **Analogia:** Isso cria o nosso **terreno privado e cercado** dentro do grande bairro que é a Oracle Cloud. Tudo que construirmos a seguir será dentro deste terreno, isolado dos outros "vizinhos".

#### Bloco 4: O Portão para a Internet (`oci_core_internet_gateway`)

```hcl
resource "oci_core_internet_gateway" "foundry_igw" { ... }
```

-   **O que faz?** Cria um "Portão de Internet".
-   **Analogia:** Nosso terreno está cercado, mas precisamos de um portão para que possamos entrar e sair para a "rua" (a internet). Este recurso é o **portão principal** do nosso terreno.

#### Bloco 5: A Tabela de Rotas (`oci_core_route_table`)

```hcl
resource "oci_core_route_table" "foundry_rt" { ... }
```

-   **O que faz?** Cria uma "Tabela de Rotas".
-   **Analogia:** Isso define as **regras de trânsito** dentro do nosso terreno. A regra que definimos (`destination = "0.0.0.0/0"`) é simples: "Qualquer tráfego que queira sair para a internet deve ir em direção ao portão principal (`foundry_igw`)".

#### Bloco 6: A Sub-rede (`oci_core_subnet`)

```hcl
resource "oci_core_subnet" "foundry_subnet" { ... }
```

-   **O que faz?** Cria uma "Sub-rede" dentro da nossa rede principal.
-   **Analogia:** Dentro do nosso terreno, estamos definindo uma **área específica onde a casa será construída**. É como o lote de construção. Nós conectamos esta área à nossa tabela de rotas, para que a casa saiba como acessar o portão principal.

#### Bloco 7: A Lista de Segurança (`oci_core_security_list`)

```hcl
resource "oci_core_security_list" "foundry_sl" { ... }
```

-   **O que faz?** Cria uma lista de regras de segurança, um *firewall*.
-   **Analogia:** Este é o **segurança na portaria do nosso condomínio (a sub-rede)**. Ele tem uma lista de quem pode entrar e em qual "porta" pode bater. Nós o instruímos a permitir:
    -   **Porta 22:** Acesso para manutenção (SSH, a nossa chave).
    -   **Porta 30000:** Acesso para os jogadores do Foundry VTT.
    -   **Portas 80 e 443:** Acesso para o Caddy, o programa que pode nos dar um endereço web bonito com cadeado (HTTPS).
    -   Qualquer outra pessoa que tente entrar por outra porta será barrada pelo segurança.

#### Bloco 8 e 9: Buscando Localização e Imagem (`data`)

```hcl
data "oci_identity_availability_domain" "ad" { ... }
data "oci_core_images" "ubuntu_image" { ... }
```

-   **O que fazem?** De novo, blocos do tipo `data`. O primeiro descobre **onde** na Oracle (em qual "bairro") há espaço para construir. O segundo procura a **versão mais recente do "sistema operacional" Ubuntu 22.04**, que será o cérebro do nosso servidor.
-   **Analogia:** O arquiteto está consultando o catálogo da construtora para escolher o "modelo de kit pré-fabricado" (a imagem do Ubuntu) mais recente para nossa casa.

#### Bloco 10: A Instância (`oci_core_instance`) - A Casa!

```hcl
resource "oci_core_instance" "foundry_instance" { ... }
```

-   **O que faz?** Finalmente, cria a **Máquina Virtual (VM)**, o nosso servidor.
-   **Analogia:** Esta é a **construção da casa em si**. Usando todas as peças que definimos antes:
    -   `availability_domain`: O local exato no terreno.
    -   `shape`: O "tamanho" da casa (quanta CPU e memória).
    -   `create_vnic_details`: Conecta a casa à nossa sub-rede e dá a ela um endereço de rua (IP Público).
    -   `source_details`: Usa o "kit pré-fabricado" do Ubuntu que escolhemos.
    -   `metadata`: A parte mais importante! Aqui ele pega a **chave SSH pública** que buscamos lá no começo (no cofre) e a instala como a **fechadura na porta da frente da casa**.

E é isso! Ao final deste arquivo, o Terraform entregou para a Oracle uma planta completa. A Oracle a executa e, no final, temos um servidor novinho em folha, dentro de uma rede segura, pronto para o próximo passo: a decoração com o Ansible.

Continue para `03_O_DECORADOR_ANSIBLE.md`.
