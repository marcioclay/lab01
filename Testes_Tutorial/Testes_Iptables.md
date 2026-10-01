# 🛡️ Guia Prático e Didático de IPTABLES

Este tutorial foi desenhado para ser executado de forma progressiva no nosso laboratório de cibersegurança. A cada etapa, você aprenderá um conceito novo e testará o resultado diretamente nos containers do ambiente.

---

## 📌 Topologia e Endereços de Referência

Antes de começar, lembre-se do mapa da nossa rede:

* **Atacante (WAN):** `192.168.10.10`
* **Firewall (WAN/LAN):** `192.168.10.1` / `192.168.20.1`
* **Cliente (LAN):** `192.168.20.10`
* **Zabbix (LAN):** `192.168.20.5`

> **Como acessar o Firewall:**  
> Todos os comandos de firewall devem ser executados no container do Firewall. Você pode entrar diretamente no terminal dele com:
> ```
> docker exec -it clab-lab01-firewall sh
> ```
> Ou executá-los diretamente a partir da sua máquina host usando `docker exec -it clab-lab01-firewall <comando>`.

---

## 🟢 Passo 1: Habilitar Roteamento e Acesso à Internet

Antes de criar regras de bloqueio, precisamos transformar nosso Linux em um roteador funcional para que a rede interna (LAN) consiga acessar a Internet.

### 1.1 Habilitar o Encaminhamento de Pacotes no Kernel
Por padrão, o Linux ignora pacotes que chegam para ele mas são destinados a outro IP. Vamos ativar o repasse de pacotes (`ip_forward`):

```
sysctl -w net.ipv4.ip_forward=1
```

## 🟢 1.2 Configurar NAT (Masquerade) para Acesso à Internet
Para que a rede LAN (192.168.20.0/24) navegue na Internet através da interface de saída (eth0), aplicamos o Masquerade na tabela nat:

```
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

## 🟢 1.3 Liberar o Repasse de Tráfego de Retorno (Stateful)
Liberamos a saída da LAN (eth2) para a Internet (eth0) e garantimos o retorno das conexões já estabelecidas:

```
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -m state --state ESTABLISHED,RELATED -j ACCEPT
```

🧪 Teste de Validação:

Vá ao container Cliente e teste o acesso à Internet:

```
docker exec -it clab-lab01-cliente ping -c 3 8.8.8.8
```
(Resultado Esperado: 0% de perda de pacotes — o cliente está navegando!).


## 🟡 Passo 2: Adicionando Regras de Filtro (-A e -I)

No iptables, existem duas formas de adicionar regras na tabela de filtragem:

* -A (Append): Adiciona a regra ao final da lista (ordem sequencial).

* -I (Insert): Insere a regra em uma posição específica (por padrão, na posição 1, no topo).

## 2.1 Visualizando as Regras Atuais

Sempre verifique o estado do firewall antes e depois de alterar regras:

```
iptables -L FORWARD -n -v
```

- Os parâmetros -n (números em vez de nomes) e -v (detalhes de pacotes e interfaces) deixam a leitura mais rápida e precisa.


## 🔴 Passo 3: Bloqueando e Liberando Acesso à Internet

Agora vamos simular um bloqueio de navegação para a rede interna.

## 3.1 Bloquear a Saída de Internet para a LAN

Vamos inserir uma regra na cadeia FORWARD bloqueando o tráfego que tenta sair da interface da LAN (eth2) em direção à Internet (eth0):

```
iptables -I FORWARD 1 -i eth2 -o eth0 -j DROP
```

🧪 Teste:

No container Cliente, tente pingar a Internet novamente:

```
docker exec -it clab-lab01-cliente ping -c 3 8.8.8.8
```

(Resultado Esperado: 100% de perda de pacotes — a navegação foi bloqueada!).


## 🔵 Passo 4: Bloqueando e Liberando IPs Específicos

Em vez de bloquear a rede toda, o administrador de rede frequentemente precisa isolar um host específico (por exemplo, um computador infectado ou um atacante externamente).

## 4.1 Bloquear um IP Específico (O Atacante)

Vamos impedir que o host Atacante (192.168.10.10) consiga alcançar o host Cliente (192.168.20.10):

```
iptables -A FORWARD -s 192.168.10.10 -d 192.168.20.10 -j DROP
```

## 4.2 Liberar Apenas um IP Específico na LAN para Navegar

Se a navegação da LAN estiver bloqueada, mas você precisar liberar exclusivamente o Zabbix (192.168.20.5) para atualizar pacotes na Internet, insira a exceção no topo da tabela:
```
iptables -I FORWARD 1 -s 192.168.20.5 -o eth0 -j ACCEPT
```


## 🟣 Passo 5: Controlando o Protocolo ICMP (Ping)

O envio de mensagens ICMP (ping) é útil para diagnósticos, mas pode ser explorado para mapeamento de rede (reconnaissance) ou ataques DoS (Ping Flood).

5.1 Bloquear ICMP (Ping) Destinado ao Próprio Firewall
Para impedir que qualquer máquina externa consiga dar ping na interface do Firewall (INPUT), execute:

```
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
```

🧪 Teste:

No container Atacante, tente pingar o IP do Firewall (192.168.10.1):

```
docker exec -it clab-lab01-atacante ping -c 3 192.168.10.1
```

(Resultado Esperado: Request timeout — o firewall ignora as requisições de ping). 



## 5.2 Liberar Ping Exclusivamente para o Servidor de Monitoramento (Zabbix)

Para permitir que apenas o Zabbix (192.168.20.5) monitore a saúde do Firewall via Ping:
```
iptables -I INPUT 1 -s 192.168.20.5 -p icmp -j ACCEPT
```

## 🧹 Passo 6: Excluindo e Limpando Regras (-D e -F)

Saber remover regras com precisão é fundamental para evitar quedas acidentais no ambiente.

## 6.1 Excluir uma Regra Específica pelo Número da Linha (Recomendado)

Passo 1: Liste as regras da cadeia desejada exibindo os números de identificação (--line-numbers):

```
iptables -L FORWARD -n --line-numbers
```
Saída de Exemplo:

| num | pkts | bytes | target | prot | opt | in | out | source | destination |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | 0 | 0 | `ACCEPT` | all | -- | `*` | `eth0` | 192.168.20.5 | 0.0.0.0/0 |
| **2** | 12 | 840 | `DROP` | all | -- | `eth2` | `eth0` | 0.0.0.0/0 | 0.0.0.0/0 |
| **3** | 0 | 0 | `DROP` | all | -- | `*` | `*` | 192.168.10.10 | 192.168.20.10 |



Passo 2: Para remover apenas o bloqueio geral de Internet (regra número 2 da cadeia FORWARD):

```
iptables -D FORWARD 2
```

## 6.2 Excluir uma Regra pela Especificação Exata

Você também pode remover reescrevendo o comando de criação, trocando a flag -A ou -I por -D (Delete):

```
iptables -D FORWARD -s 192.168.10.10 -d 192.168.20.10 -j DROP
```

## 6.3 Limpar Todas as Regras (Flush)

* Limpar apenas uma cadeia específica (ex: FORWARD):
```
iptables -F FORWARD
```

* Zerar e restaurar TODO o firewall para o estado inicial:

- iptables -F        # Limpa todas as regras de filtragem
- iptables -t nat -F  # Limpa todas as regras de NAT
- iptables -X        # Apaga cadeias personalizadas criadas pelo usuário
- iptables -Z        # Zera os contadores de pacotes e bytes



| Ação | Comando Didático de Exemplo |
| :--- | :--- |
| **Listar regras com números** | `iptables -L FORWARD -n --line-numbers` |
| **Adicionar no final** | `iptables -A FORWARD -s 192.168.10.10 -j DROP` |
| **Inserir no topo (prioridade)** | `iptables -I FORWARD 1 -s 192.168.20.5 -j ACCEPT` |
| **Bloquear Ping (ICMP)** | `iptables -A INPUT -p icmp -j DROP` |
| **Excluir regra por linha** | `iptables -D FORWARD 1` |
| **Limpar tudo (Flush)** | `iptables -F` |















