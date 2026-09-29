# 🛡️ Guia Didático: Conceitos de Firewall e IPTABLES na Prática

---

## 1. O que é um Firewall?

Um **firewall** é um dispositivo de segurança de rede encarregado de inspecionar e controlar o tráfego que entra, sai ou atravessa uma rede. 

Uma analogia prática é o trabalho de uma **portaria de condomínio**:
* Todo visitante que chega precisa apresentar identificação (*IP de origem*).
* Informar qual apartamento deseja visitar (*IP de destino*).
* Especificar o objetivo da visita (*Porta e Protocolo, como HTTP/80 ou SSH/22*).
* O porteiro consulta a lista de regras: se a entrada estiver liberada, a passagem é **permitida (`ACCEPT`)**; caso contrário, a entrada é **negada (`DROP` ou `REJECT`)**.

---

## 2. O que é o IPTABLES?

O `iptables` é a ferramenta de linha de comando padrão em sistemas Linux utilizada para configurar as tabelas de filtragem de pacotes fornecidas pelo módulo **Netfilter** do próprio Kernel do Linux.

Como o `iptables` opera diretamente dentro do Kernel, ele possui altíssimo desempenho para processar e tomar decisões sobre pacotes de rede em tempo real.

---

## 3. Estrutura de Funcionamento: Chains (Cadeias) e Actions (Ações)

O `iptables` organiza as regras na tabela principal de segurança chamada **`filter`**, dividida em **3 cadeias nativas (Chains)** que representam o caminho do fluxo de rede no sistema:

```text
                           PACOTE CHEGA À INTERFACE
                                      │
                                      ▼
                        ┌───────────────────────────┐
                        │   Endereçado ao Firewall? │
                        └─────────────┬─────────────┘
                                      │
                      ┌───────────────┴───────────────┐
                     Sim                             Não
                      │                               │
                      ▼                               ▼
            ┌──────────────────┐            ┌──────────────────┐
            │   Chain INPUT    │            │  Chain FORWARD   │
            └──────────────────┘            └──────────────────┘
                      │                               │
                      ▼                               ▼
             Processo Interno                 Atravessa para a LAN
                      │
                      ▼
            ┌──────────────────┐
            │   Chain OUTPUT   │
            └──────────────────┘
```

### As 3 Chains Principais
* **`INPUT`**: Pacotes cujo destino final é o **próprio firewall**.
  * *Exemplo:* O servidor Zabbix disparando um ping contra o IP da interface interna do Firewall (`192.168.20.1`).
* **`FORWARD`**: Pacotes que **atravessam o firewall** de uma rede para outra (roteamento).
  * *Exemplo:* Pacotes enviados pelo Atacante (`192.168.10.10`) tentando alcançar o Cliente (`192.168.20.10`).
* **`OUTPUT`**: Pacotes **gerados pelo próprio firewall** e destinados ao exterior.
  * *Exemplo:* O firewall fazendo um download de atualização de sistema no repositório web.

### As Ações (Targets)
Ao encontrar uma correspondência com uma regra, o `iptables` aplica uma das ações:
* **`ACCEPT`**: Permite a passagem do pacote[cite: 1].
* **`DROP`**: Descarta o pacote silenciosamente (a origem não recebe nenhuma notificação e sofre *timeout*)[cite: 1].
* **`REJECT`**: Descarta o pacote enviando uma mensagem explícita de recusa (ICMP Destination Unreachable) para a origem[cite: 1].

---

## 4. Topologia do Laboratório de Referência

Todos os exemplos de comandos a seguir utilizam o endereçamento da nossa topologia de duas sub-redes:

```text
[ WAN: 192.168.10.0/24 ]                  [ LAN: 192.168.20.0/24 ]
  atacante (192.168.10.10)                 cliente (192.168.20.10)
            │                                         │
            ▼                                         ▼
      (switch1 WAN)                             (switch2 LAN)
            │                                         │
            └──────────►  firewall (192.168.10.1) ◄───┘
                          firewall (192.168.20.1)
                                    ▲
                                    │
                          zabbix (192.168.20.5)
```

## 5. Prática do IPTABLES: Visualizar, Incluir e Excluir Regras
👁️ A. Visualizando Regras

1. Listagem Simples
Listar todas as regras ativas de todas as cadeias:

```
iptables -L
```

2. Listagem Detalhada e Rápida (Recomendada para Produção e Aulas)
Adiciona o parâmetro -n (não resolve nomes de domínio/DNS, evitando lentidão) e -v (exibe contadores de pacotes/bytes e interfaces):

```
iptables -L -n -v
```

3. Listagem com Números de Linha (Essencial para Exclusão)
Exibe o número identificador (num) ao lado de cada regra de uma chain específica:

```
iptables -L FORWARD -n --line-numbers
```

➕ B. Incluindo Regras (-A e -I)
Existem duas formas de inserir regras: Append (-A), que adiciona ao final da lista, e Insert (-I), que insere em uma posição específica (por padrão, no topo).

1. Exemplo de INPUT (Adicionar ao final com -A)
Liberar o monitoramento via ICMP (Ping) vindo exclusivamente do Zabbix (192.168.20.5) para o próprio Firewall[cite: 1]:

```
iptables -A INPUT -p icmp -s 192.168.20.5 -j ACCEPT
```


2. Exemplo de FORWARD (Bloqueio de Atacante)
Bloquear todo o tráfego que o Atacante (192.168.10.10) tentar enviar para o Cliente (192.168.20.10) atravessando o Firewall:

```
iptables -A FORWARD -s 192.168.10.10 -d 192.168.20.10 -j DROP
```

3. Exemplo de Inserção Prioritária (-I)
Inserir uma regra no topo da cadeia FORWARD (posição 1) para priorizar a liberação da porta HTTP (80) antes de qualquer bloqueio:

```
iptables -I FORWARD 1 -p tcp --dport 80 -j ACCEPT
```

🗑️ C. Excluindo e Limpando Regras

1. Excluir por Número da Linha (Forma mais segura)
Primeiro, consulte a numeração das regras:

```
iptables -L FORWARD -n --line-numbers
```

Saída de exemplo: 

Chain FORWARD (policy ACCEPT)
num  pkts bytes target     prot opt in     out     source           destination          
1    150  9000  ACCEPT     tcp  --  *      *       0.0.0.0/0        0.0.0.0/0            tcp dpt:80
2     45  2700  DROP       all  --  *      *       192.168.10.10    192.168.20.10

Para apagar a regra número 2 da cadeia FORWARD:

```
iptables -D FORWARD 2
```

2. Excluir pela Especificação Exata da Regra
Reescreva a regra exatamente como foi criada, substituindo o parâmetro de adição (-A) por exclusão (-D):

```
iptables -D FORWARD -s 192.168.10.10 -d 192.168.20.10 -j DROP
```

3. Limpar Parcialmente (Flush em uma Chain Específica)
Remover todas as regras cadastradas apenas na cadeia FORWARD, sem afetar INPUT ou OUTPUT:

```
iptables -F FORWARD
```

4. Limpar Tudo (Flush Total do Firewall)
Remover todas as regras personalizadas de todas as cadeias do firewall:

```
iptables -F
iptables -X  # Apaga cadeias personalizadas criadas pelo usuário
iptables -Z  # Zera os contadores de pacotes e bytes
```

## 6. Resumo Rápido dos Parâmetros Mais Utilizados

| Parâmetro | Significado | Exemplo de Aplicação |
| :--- | :--- | :--- |
| **`-A`** | Append (Adiciona ao final) | `iptables -A INPUT ...` |
| **`-I`** | Insert (Insere no topo/posição) | `iptables -I FORWARD 1 ...` |
| **`-D`** | Delete (Remove regra) | `iptables -D FORWARD 2` |
| **`-L`** | List (Lista as regras) | `iptables -L -n -v` |
| **`-F`** | Flush (Limpa todas as regras) | `iptables -F` |
| **`-p`** | Protocolo (tcp, udp, icmp) | `-p tcp` ou `-p icmp` |
| **`-s`** | Source (IP ou Rede de origem) | `-s 192.168.10.10` |
| **`-d`** | Destination (IP ou Rede de destino) | `-d 192.168.20.10` |
| **`--dport`** | Destination Port (Porta de destino) | `--dport 80` ou `--dport 22` |
| **`-j`** | Jump / Action (Ação a ser tomada) | `-j ACCEPT`, `-j DROP`, `-j REJECT` |

