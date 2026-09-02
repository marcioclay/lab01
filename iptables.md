# 🛡️ Firewall com IPTABLES

## 1. Objetivos da aula

Ao final desta aula, você deverá ser capaz de:

* Entender o que é um **firewall**.
* Identificar a função do `iptables` no Linux.
* Entender o conceito de **regra de firewall**.
* Identificar origem, destino, protocolo e porta de uma comunicação.
* Criar regras simples utilizando `iptables`.
* Permitir ou bloquear determinados tipos de tráfego.
* Testar as regras utilizando `ping`, `curl` e conexões de rede.
* Compreender a função do firewall dentro de uma topologia de rede.
* Utilizar o **Docker + Containerlab** para montar um laboratório de firewall.

---

# 2. O que é um Firewall?

Um **firewall** é um mecanismo utilizado para controlar o tráfego de rede.

Imagine que uma rede possui vários computadores:

```text
Cliente ──────────────── Servidor
   │
   │
Atacante
```

Todos esses equipamentos podem tentar se comunicar.

O firewall funciona como um **ponto de controle**:

```text
Cliente ───────┐
               │
               ▼
          ┌───────────┐
          │ FIREWALL  │
          └───────────┘
               │
               ▼
            Servidor
```

Antes que uma comunicação seja permitida, o firewall pode verificar algumas informações.

Por exemplo:

* Quem está enviando?
* Para onde está indo?
* Qual protocolo está sendo utilizado?
* Qual porta está sendo utilizada?
* A comunicação deve ser permitida?
* A comunicação deve ser bloqueada?

---

# 3. Exemplo do mundo real

Imagine a portaria de uma empresa.

Uma pessoa chega e deseja entrar.

O segurança pode perguntar:

> Quem é você?

Depois:

> Para onde você vai?

E então:

> Você tem autorização para entrar?

O firewall funciona de maneira semelhante.

Podemos representar:

```text
ORIGEM        DESTINO       SERVIÇO       AÇÃO
Cliente   →   Servidor      HTTP:80       PERMITIR
Atacante  →   Servidor      SSH:22        BLOQUEAR
Cliente   →   Servidor      HTTPS:443     PERMITIR
```

Uma regra de firewall basicamente determina:

> **O que fazer quando determinado tráfego for identificado.**

---

# 4. Firewall baseado em regras

Um firewall normalmente trabalha com um conjunto de regras.

Por exemplo:

```text
Regra 1 → Permitir HTTP
Regra 2 → Permitir HTTPS
Regra 3 → Bloquear SSH
Regra 4 → Bloquear todo o restante
```

Quando um pacote chega ao firewall, as regras são analisadas.

Um conceito muito importante é:

> **A ordem das regras importa.**

Considere:

```text
Regra 1: PERMITIR TCP porta 80
Regra 2: BLOQUEAR TCP porta 80
```

Se uma conexão HTTP chegar, a primeira regra poderá ser aplicada antes da segunda.

Por isso, devemos ter cuidado ao criar regras.

---

# 5. O que é o IPTABLES?

O `iptables` é uma ferramenta tradicional do Linux utilizada para configurar regras de filtragem de pacotes.

Ele permite controlar o tráfego que passa pelo sistema operacional.

Por exemplo:

```bash
iptables -L
```

Esse comando permite visualizar regras existentes.

Podemos pensar no `iptables` como uma espécie de:

```text
                Linux
                  │
          ┌───────▼───────┐
          │    IPTABLES    │
          │                │
          │ Regras de      │
          │ firewall       │
          └───────┬────────┘
                  │
          Tráfego permitido
          ou bloqueado
```

---

# 6. Onde o IPTABLES funciona?

O `iptables` funciona no sistema operacional Linux.

Por isso, podemos transformar um computador Linux em um firewall.

No nosso laboratório, teremos um **host Linux atuando como firewall**.

```text
Rede
  │
  ▼
┌─────────────┐
│   Firewall  │
│   Linux     │
│  iptables   │
└─────────────┘
```

O firewall terá a responsabilidade de controlar o tráfego entre as redes.

---

# 7. Topologia do laboratório

Nosso laboratório será construído utilizando:

* Docker
* Containerlab
* Linux
* IPTABLES

A topologia terá:

* 1 host atacante
* 1 host cliente
* 1 host servidor
* 1 firewall
* 2 switches

A representação será:

```text
                    REDE EXTERNA

                ┌───────────────┐
                │   Atacante   │
                └───────┬───────┘
                        │
                        │
                 ┌──────▼──────┐
                 │   Switch 1  │
                 └──────┬──────┘
                        │
                        │
                 ┌──────▼──────┐
                 │  FIREWALL   │
                 │   IPTABLES  │
                 └──────┬──────┘
                        │
                        │
                 ┌──────▼──────┐
                 │   Switch 2  │
                 └──────┬──────┘
                        │
              ┌─────────┴─────────┐
              │                   │
       ┌──────▼──────┐     ┌──────▼──────┐
       │   Cliente   │     │   Servidor  │
       └─────────────┘     └─────────────┘

                    REDE INTERNA
```

---

# 8. Função de cada equipamento

## Atacante

O host atacante será utilizado para gerar tráfego contra o servidor.

Por exemplo:

```text
Atacante → Servidor
```

Podemos utilizar ferramentas como:

```bash
ping
curl
nc
```

O objetivo inicialmente não é realizar um ataque complexo.

Queremos simplesmente gerar tráfego e observar o comportamento do firewall.

---

## Cliente

O cliente representa um equipamento legítimo da rede.

Por exemplo:

```text
Cliente → Servidor
```

Esse tráfego deverá ser permitido pelas regras do firewall.

---

## Servidor

O servidor disponibilizará algum serviço de rede.

Por exemplo:

```text
HTTP
```

Podemos executar um servidor web simples.

O cliente poderá acessar:

```bash
curl http://IP_DO_SERVIDOR
```

---

## Switches

Os switches serão responsáveis pela interligação dos dispositivos.

Teremos duas redes:

```text
REDE EXTERNA
      │
   Switch 1
      │
   Firewall
      │
   Switch 2
      │
REDE INTERNA
```

O firewall ficará entre as duas redes.

---

# 9. O Firewall como uma "barreira"

Uma das ideias mais importantes desta aula é entender que o firewall fica **entre as redes**.

Sem firewall:

```text
Atacante ───────────────► Servidor
```

O atacante consegue tentar estabelecer comunicação diretamente com o servidor.

Com firewall:

```text
Atacante
   │
   ▼
┌───────────┐
│ FIREWALL  │
│ IPTABLES  │
└─────┬─────┘
      │
      ▼
   Servidor
```

Agora o tráfego precisa passar pelas regras do firewall.

---

# 10. Endereçamento IP

Para facilitar o laboratório, vamos utilizar duas redes diferentes.

### Rede externa

```text
192.168.10.0/24
```

Exemplo:

```text
Atacante:
192.168.10.10
```

Interface externa do firewall:

```text
192.168.10.1
```

---

### Rede interna

```text
192.168.20.0/24
```

Exemplo:

```text
Cliente:
192.168.20.10

Servidor:
192.168.20.20
```

Interface interna do firewall:

```text
192.168.20.1
```

A topologia lógica ficará:

```text
192.168.10.0/24
          │
          │
     ┌────▼────┐
     │ Firewall│
     └────┬────┘
          │
192.168.20.0/24
          │
     ┌────┴────┐
     │         │
 Cliente    Servidor
```

---

# 11. Por que o firewall precisa de duas interfaces?

O firewall está conectando duas redes diferentes.

Portanto, ele precisa possuir uma interface em cada rede.

```text
                 FIREWALL
        ┌──────────────────────┐
        │                      │
        │ eth0          eth1   │
        │  │             │     │
        └──┼─────────────┼─────┘
           │             │
           ▼             ▼
        REDE 1         REDE 2
```

Exemplo:

```text
eth0 → 192.168.10.1
eth1 → 192.168.20.1
```

---

# 12. Gateway

Um equipamento que precisa acessar outra rede normalmente utiliza um **gateway**.

Por exemplo, o servidor está na rede:

```text
192.168.20.0/24
```

Seu gateway será:

```text
192.168.20.1
```

Que corresponde à interface interna do firewall.

Assim:

```text
Servidor
192.168.20.20
      │
      │ gateway
      ▼
Firewall
192.168.20.1
```

O firewall poderá encaminhar o tráfego para outra rede.

---

# 13. Encaminhamento de pacotes

Um firewall que atua como roteador precisa permitir o **encaminhamento de pacotes**.

No Linux, isso está relacionado ao parâmetro:

```text
ip_forward
```

Podemos verificar:

```bash
cat /proc/sys/net/ipv4/ip_forward
```

Se aparecer:

```text
1
```

o encaminhamento está habilitado.

Se aparecer:

```text
0
```

o encaminhamento está desabilitado.

Para habilitar temporariamente:

```bash
sysctl -w net.ipv4.ip_forward=1
```

---

# 14. Entendendo uma regra do IPTABLES

Uma regra pode ser interpretada como:

```text
SE determinado tráfego acontecer
ENTÃO execute uma ação.
```

Por exemplo:

```text
SE
origem = 192.168.10.10
E
destino = 192.168.20.20
E
protocolo = TCP
E
porta = 80

ENTÃO
PERMITIR
```

Isso pode ser representado:

```text
Atacante
192.168.10.10
      │
      │ TCP/80
      ▼
Firewall
      │
      │ PERMITIDO
      ▼
Servidor
192.168.20.20
```

---

# 15. Comando básico do IPTABLES

Uma regra simples pode ser criada com:

```bash
iptables -A INPUT -p icmp -j DROP
```

Vamos entender cada parte.

### `iptables`

Executa a ferramenta.

### `-A`

Significa **Append**.

Adiciona uma regra.

### `INPUT`

Indica tráfego destinado ao próprio firewall.

### `-p icmp`

Indica o protocolo ICMP.

O `ping` utiliza ICMP.

### `-j DROP`

Indica a ação.

```text
DROP = descartar
```

Portanto:

```bash
iptables -A INPUT -p icmp -j DROP
```

significa:

> Descartar pacotes ICMP destinados ao próprio firewall.

---

# 16. INPUT, OUTPUT e FORWARD

Esse é um dos conceitos mais importantes do `iptables`.

Existem três chains fundamentais para esta aula:

```text
INPUT
OUTPUT
FORWARD
```

## INPUT

Tráfego que está entrando **no próprio firewall**.

```text
Cliente ─────► Firewall
```

Exemplo:

```text
ping → Firewall
```

---

## OUTPUT

Tráfego que está saindo **do próprio firewall**.

```text
Firewall ─────► Servidor
```

---

## FORWARD

Tráfego que **passa pelo firewall** para chegar a outro equipamento.

```text
Atacante
    │
    ▼
Firewall
    │
    ▼
Servidor
```

Esse é especialmente importante no nosso laboratório.

O pacote não tem como destino o firewall.

Ele está apenas passando pelo firewall.

Portanto:

```text
FORWARD
```

será uma das principais chains utilizadas no laboratório.

---

# 17. Exemplo de FORWARD

Imagine:

```text
Atacante
192.168.10.10
       │
       ▼
   Firewall
       │
       ▼
Servidor
192.168.20.20
```

Queremos bloquear o atacante.

Uma regra conceitualmente poderia ser:

```bash
iptables -A FORWARD -s 192.168.10.10 -d 192.168.20.20 -j DROP
```

Interpretando:

```text
-A FORWARD
```

Adiciona uma regra na chain FORWARD.

```text
-s 192.168.10.10
```

Define a origem.

`-s` significa:

```text
source = origem
```

```text
-d 192.168.20.20
```

Define o destino.

`-d` significa:

```text
destination = destino
```

```text
-j DROP
```

Descarta o pacote.

Portanto:

> Todo tráfego encaminhado do atacante para o servidor será descartado.

---

# 18. DROP x ACCEPT

Duas ações muito importantes são:

```text
ACCEPT
DROP
```

### ACCEPT

Permite o pacote.

```text
ACCEPT = PERMITIR
```

### DROP

Descarta o pacote.

```text
DROP = DESCARTAR
```

Visualmente:

```text
          Pacote
             │
             ▼
        ┌──────────┐
        │ Firewall │
        └────┬─────┘
             │
       ┌─────┴─────┐
       │           │
       ▼           ▼
    ACCEPT        DROP
       │           │
       ▼           X
   Continua      Descartado
```

---

# 19. REJECT x DROP

Existe ainda:

```text
REJECT
```

A diferença básica é:

### DROP

O firewall simplesmente descarta o pacote.

```text
Cliente ───► Firewall ───X
```

O cliente pode ficar esperando uma resposta até ocorrer um timeout.

### REJECT

O firewall descarta a comunicação e envia uma resposta indicando que ela foi rejeitada.

De maneira simplificada:

```text
Cliente ───► Firewall
                │
                ▼
             REJECT
                │
                ▼
        Resposta ao cliente
```

No laboratório, vamos experimentar principalmente `DROP`.

---

# 20. Listando as regras

Para visualizar as regras:

```bash
iptables -L
```

Uma forma mais detalhada:

```bash
iptables -L -n -v
```

Podemos observar informações como:

* chain;
* origem;
* destino;
* protocolo;
* ação;
* quantidade de pacotes;
* quantidade de bytes.

Exemplo conceitual:

```text
Chain FORWARD

target   prot   source          destination
DROP     tcp    192.168.10.10  192.168.20.20
```

---

# 21. Contadores de pacotes

O `iptables` pode contar quantos pacotes passaram por uma regra.

Por exemplo:

```bash
iptables -L -n -v
```

Podemos encontrar:

```text
pkts
bytes
```

Isso é muito útil para entender o funcionamento do firewall.

Imagine:

```text
Atacante
   │
   │ 100 pacotes
   ▼
Firewall
   │
   │ DROP
   X
```

Depois podemos consultar:

```bash
iptables -L -n -v
```

e observar que a regra recebeu os pacotes.

---

# 22. Testando o laboratório

Depois que a topologia estiver funcionando, começaremos sem nenhuma regra de bloqueio.

## Teste 1 — Cliente → Servidor

No cliente:

```bash
ping 192.168.20.20
```

Esperamos que haja resposta.

---

## Teste 2 — Atacante → Servidor

No atacante:

```bash
ping 192.168.20.20
```

Inicialmente, também deverá existir comunicação.

Isso é importante porque queremos observar o comportamento **antes e depois da regra**.

---

# 23. Criando uma regra de bloqueio

Agora vamos bloquear o atacante.

No firewall:

```bash
iptables -A FORWARD -s 192.168.10.10 -d 192.168.20.20 -j DROP
```

Agora teste novamente:

```bash
ping 192.168.20.20
```

O resultado esperado é:

```text
Atacante ─────► Firewall ─────X────► Servidor
                    DROP
```

O atacante não deverá conseguir completar a comunicação.

---

# 24. O cliente continua funcionando?

Agora faça o teste no cliente:

```bash
ping 192.168.20.20
```

O cliente deverá continuar conseguindo acessar o servidor.

Isso demonstra uma característica importante do firewall:

> Podemos bloquear uma origem específica sem necessariamente bloquear toda a rede.

Observe:

```text
Atacante
192.168.10.10
      │
      ▼
  FIREWALL
      │
      X
      │
  Servidor

Cliente
192.168.20.10
      │
      ▼
  FIREWALL
      │
      ▼
  Servidor
```

---

# 25. Bloqueando uma porta específica

Firewall não precisa necessariamente bloquear todo o tráfego.

Podemos bloquear apenas determinado serviço.

Por exemplo:

```text
Servidor
    │
    ├── HTTP 80
    ├── HTTPS 443
    └── SSH 22
```

Podemos permitir:

```text
HTTP → permitido
```

e bloquear:

```text
SSH → bloqueado
```

Uma regra pode especificar:

```bash
-p tcp
```

para TCP e:

```bash
--dport 22
```

para a porta de destino.

Exemplo:

```bash
iptables -A FORWARD -s 192.168.10.10 -d 192.168.20.20 -p tcp --dport 22 -j DROP
```

Interpretando:

> Bloquear conexões TCP da máquina atacante para a porta 22 do servidor.

---

# 26. Testando uma porta

Podemos verificar se uma porta está acessível utilizando:

```bash
nc
```

Por exemplo:

```bash
nc -zv 192.168.20.20 22
```

Ou, se o servidor possuir HTTP:

```bash
curl http://192.168.20.20
```

A ideia é observar:

```text
ANTES DA REGRA

Atacante → Firewall → Servidor
                    ✓


DEPOIS DA REGRA

Atacante → Firewall ──X──→ Servidor
                    DROP
```

---

# 27. A importância da ordem das regras

Imagine que temos:

```text
Regra 1 → ACCEPT
Regra 2 → DROP
```

Se o pacote corresponder à primeira regra, ele poderá ser aceito antes de chegar à segunda.

Por isso devemos pensar cuidadosamente na ordem.

Exemplo:

```text
1. Permitir Cliente → Servidor HTTP
2. Bloquear Atacante → Servidor HTTP
3. Bloquear restante
```

A organização das regras faz parte da segurança.

---

# 28. Política padrão

Além das regras individuais, podemos definir uma política padrão.

Por exemplo:

```bash
iptables -P FORWARD DROP
```

Isso significa:

> Por padrão, o tráfego encaminhado será bloqueado.

A partir disso, precisamos criar regras explícitas para permitir o que é necessário.

Conceitualmente:

```text
          TRÁFEGO
             │
             ▼
        ┌──────────┐
        │ FORWARD  │
        └────┬─────┘
             │
      ┌──────┴──────┐
      │             │
      ▼             ▼
   Regra         Sem regra
      │             │
      ▼             ▼
   ACCEPT          DROP
```

Essa estratégia é conhecida como:

> **Default Deny**

Ou seja:

> Negar por padrão e permitir somente o que for necessário.

---

# 29. Cuidado com a política DROP

Durante o laboratório, tenha cuidado com:

```bash
iptables -P INPUT DROP
```

ou:

```bash
iptables -P FORWARD DROP
```

Uma política `DROP` pode bloquear praticamente toda a comunicação correspondente àquela chain.

Por isso, antes de utilizar uma política restritiva, devemos compreender quais regras são necessárias.

---

# 30. Limpando as regras

Para remover as regras criadas:

```bash
iptables -F
```

`-F` significa:

```text
Flush
```

ou seja, limpar as regras.

Depois podemos verificar:

```bash
iptables -L -n -v
```

---

# 31. Fluxo completo do laboratório

Nosso exercício seguirá esta sequência:

```text
1. Criar a topologia
        │
        ▼
2. Configurar os endereços IP
        │
        ▼
3. Configurar os gateways
        │
        ▼
4. Habilitar IP forwarding
        │
        ▼
5. Testar comunicação
        │
        ▼
6. Visualizar regras do IPTABLES
        │
        ▼
7. Criar regra DROP
        │
        ▼
8. Testar novamente
        │
        ▼
9. Observar os contadores
        │
        ▼
10. Criar regra para uma porta
        │
        ▼
11. Testar novamente
```

---

# 32. Docker e Containerlab

Nosso laboratório será executado em containers.

Isso permite criar uma rede virtual sem precisar de vários computadores físicos.

Podemos representar:

```text
Container
    │
    ├── Atacante
    │
    ├── Cliente
    │
    ├── Servidor
    │
    └── Firewall
```

O **Containerlab** será responsável por criar e conectar os elementos da topologia.

A ideia é aproximar o laboratório de uma rede real:

```text
               Containerlab

      ┌──────────────┐
      │   Atacante   │
      └──────┬───────┘
             │
         ┌───▼───┐
         │Switch │
         └───┬───┘
             │
       ┌─────▼─────┐
       │  Firewall │
       │  iptables │
       └─────┬─────┘
             │
         ┌───▼───┐
         │Switch │
         └───┬───┘
             │
       ┌─────┴─────┐
       │           │
   Cliente      Servidor
```

---

# 33. O que devemos observar durante o laboratório?

Durante os testes, não devemos apenas verificar se o `ping` funciona.

Devemos observar:

### Antes do firewall

```text
Atacante → Servidor
     ✓
```

### Depois da regra

```text
Atacante → Firewall → Servidor
                    X
```

E verificar:

```bash
iptables -L -n -v
```

Pergunte:

> O contador de pacotes da regra aumentou?

Se aumentou, significa que os pacotes estão correspondendo à regra.

---

# 34. Conceitos importantes

Ao final da aula, você deverá compreender:

| Conceito  | Significado                                  |
| --------- | -------------------------------------------- |
| Firewall  | Controla o tráfego de rede                   |
| IPTABLES  | Ferramenta de firewall do Linux              |
| Regra     | Define como determinado tráfego será tratado |
| ACCEPT    | Permite o tráfego                            |
| DROP      | Descarta o tráfego                           |
| REJECT    | Rejeita o tráfego informando o remetente     |
| INPUT     | Tráfego destinado ao firewall                |
| OUTPUT    | Tráfego originado pelo firewall              |
| FORWARD   | Tráfego que passa pelo firewall              |
| `-s`      | Define a origem                              |
| `-d`      | Define o destino                             |
| `-p`      | Define o protocolo                           |
| `--dport` | Define a porta de destino                    |
| `-A`      | Adiciona uma regra                           |
| `-L`      | Lista as regras                              |
| `-F`      | Limpa as regras                              |
| `-P`      | Define a política padrão                     |

---

# 35. Exercício prático

## Desafio 1 — Bloquear o atacante

Configure uma regra para impedir que:

```text
Atacante
192.168.10.10
```

acesse:

```text
Servidor
192.168.20.20
```

### Pergunta

Qual regra do `iptables` deverá ser utilizada?

---

## Desafio 2 — Permitir o cliente

O cliente:

```text
192.168.20.10
```

deve continuar acessando o servidor.

Teste:

```bash
ping 192.168.20.20
```

### Pergunta

O bloqueio do atacante afetou o cliente?

Explique.

---

## Desafio 3 — Bloquear uma porta

Considere que o servidor possui SSH:

```text
TCP/22
```

Crie uma regra para impedir que o atacante acesse essa porta.

Teste utilizando:

```bash
nc -zv 192.168.20.20 22
```

---

## Desafio 4 — Observar os contadores

Execute:

```bash
iptables -L -n -v
```

Antes do teste e depois do teste.

Observe:

```text
pkts
bytes
```

### Pergunta

O que aconteceu com os contadores depois que o atacante tentou acessar o servidor?

---

# 36. Resumo da aula

Podemos resumir o funcionamento do firewall da seguinte maneira:

```text
                    PACOTE
                       │
                       ▼
                ┌─────────────┐
                │  FIREWALL   │
                │  IPTABLES   │
                └──────┬──────┘
                       │
                 Verifica regras
                       │
             ┌─────────┴─────────┐
             │                   │
             ▼                   ▼
          ACCEPT                DROP
             │                   │
             ▼                   X
        Pacote segue          Pacote
                              descartado
```

O principal conceito desta aula é:

> **Um firewall controla o tráfego utilizando regras que determinam quais comunicações podem passar e quais devem ser bloqueadas.**

No nosso laboratório, o `iptables` será utilizado no **firewall Linux**, que ficará entre a rede externa e a rede interna.

```text
ATACANTE
   │
   ▼
SWITCH 1
   │
   ▼
FIREWALL
IPTABLES
   │
   ▼
SWITCH 2
   │
   ├────────► CLIENTE
   │
   └────────► SERVIDOR
```

A partir dessa estrutura, podemos evoluir o laboratório para estudar:

* filtragem por IP;
* filtragem por protocolo;
* filtragem por porta;
* políticas padrão;
* contadores de pacotes;
* NAT;
* regras de encaminhamento;
* bloqueio de ataques;
* monitoramento do firewall;
* integração entre firewall e mecanismos de segurança de rede.

---

# 📌 Comandos essenciais

```bash
# Verificar IP
ip addr

# Verificar rotas
ip route

# Verificar IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# Habilitar IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Listar regras
iptables -L

# Listar regras com detalhes e contadores
iptables -L -n -v

# Adicionar regra
iptables -A FORWARD ...

# Limpar regras
iptables -F

# Definir política padrão
iptables -P FORWARD DROP
```

> **Regra de ouro:** antes de criar uma regra de firewall, pense sempre em **origem → destino → protocolo → porta → ação**.

Exemplo:

```text
ORIGEM             DESTINO             PROTOCOLO     PORTA     AÇÃO

192.168.10.10  →   192.168.20.20       TCP           80       DROP
```

Essa forma de pensar facilitará bastante a criação e a análise das regras de firewall.
