# 💥 Laboratório Prático: Simulação e Análise de Ataque DDoS com `hping3`, `tcpdump` e Wireshark

Este guia contém o roteiro completo para a realização da prática de **simulação de ataque DDoS com falsificação de IP (*IP Spoofing*)**, análise do impacto no ambiente (CPU, memória, QoS e perda de pacotes), captura e inspeção de pacotes `.pcap` com Wireshark, e mitigação com regras de *Rate Limiting* no `iptables`.

---

## 📌 Topologia e Mapeamento do Ambiente

* **Atacante (WAN):** `192.168.10.10` (Origem do tráfego com IPs aleatórios)
* **Firewall (Gateway):** `192.168.10.1` (WAN / `eth1`) e `192.168.20.1` (LAN / `eth2`)
* **Cliente / Alvo (LAN):** `192.168.20.10`
* **Volume Compartilhado:** Pasta `./scripts` do host mapeada em `/scripts` dentro dos containers.

---

## 📊 Passo 1: Preparar os Painéis de Monitoramento

Antes de iniciar o ataque, abra **3 terminais no seu computador (host)** para acompanhar as métricas em tempo real.

### Terminal 1: Monitorar CPU e Memória no Firewall
No primeiro terminal, acompanhe o processador e o consumo do Firewall:
```
docker exec -it clab-lab01-firewall top
```

💡 O que observar: Atente-se à métrica %si (Software Interrupts). Em ataques de volumetria, o Kernel consome altos ciclos de CPU processando as interrupções da placa de rede antes do tráfego chegar às aplicações.


### Terminal 2: Monitorar Vazão e Taxa de Pacotes (QoS)
No segundo terminal, acompanhe os contadores da interface vinda da WAN (eth1):

```
docker exec -it clab-lab01-firewall watch -n 1 "ip -s link show eth1"
```
💡 O que observar: Acompanhe o crescimento das métricas RX packets e bytes 


### Terminal 3: Monitorar a Conectividade no Cliente
No terceiro terminal, execute um teste de latência contínuo no Cliente:

```
docker exec -it clab-lab01-cliente ping 192.168.20.1
```

💡 O que observar: A latência padrão em tempo normal deve ser inferior a 1ms com 0% de perda de pacotes. 

## 📡 Passo 2: Iniciar a Captura de Pacotes (.pcap) no Firewall
Para salvar as evidências do ataque e analisar a falsificação de IPs no Wireshark, inicie o tcpdump gravando diretamente no diretório compartilhado /scripts:

```
docker exec -d clab-lab01-firewall tcpdump -i eth1 -n -c 20000 -w /scripts/ataque_ddos.pcap "tcp[tcpflags] & (tcp-syn) != 0"
```

* -i eth1: Captura o tráfego que chega pela interface externa (WAN).

* -n: Não perde tempo tentando resolver nomes via DNS.

* -c 20000: Captura exatamente 20.000 pacotes e encerra a gravação automaticamente.

* -w /scripts/ataque_ddos.pcap: Salva o arquivo diretamente na pasta montada no repositório. 


## 🚀 Passo 3: Lançar o Ataque DDoS (hping3 + IP Spoofing)
Em um quarto terminal no host, inicie o ataque executando a ferramenta a partir do container atacante:

```
docker exec -it clab-lab01-atacante hping3 --flood -S -p 80 --rand-source 192.168.20.10
``` 

🧩 Entendendo os Parâmetros do hping3: 

* --flood: Dispara os pacotes na máxima velocidade suportada pelo sistema (modo inundação).

* -S: Define a flag do cabeçalho TCP como SYN (SYN Flood).

* -p 80: Aponta para a porta de serviço HTTP do alvo.

* --rand-source: Gera o efeito DDoS. Falsifica o IP de origem de cada pacote com endereços aleatórios (ex: 185.22.1.4, 45.10.201.88).

* 192.168.20.10: Endereço do Cliente/Alvo localizado na rede interna.


## 🔍 Passo 4: Diagnóstico Visual do Ataque

Enquanto o hping3 estiver rodando, observe o comportamento nos três terminais de monitoramento:

- Esgotamento de Recursos no Firewall (Terminal 1): O uso do processador na métrica %si subirá drasticamente devido à carga de interrupção da placa de rede.

- Explosão do Volume de Pacotes (Terminal 2): Os contadores RX packets na interface eth1 crescerão em dezenas de milhares de pacotes por segundo.

- Negação de Serviço / Queda de Conectividade (Terminal 3): O ping no Cliente passará a apresentar estouros de tempo (Request Timeout) ou latência extrema, confirmando a perda de qualidade do serviço (QoS).

Pressione Ctrl + C no terminal do atacante para interromper o envio após visualizar o impacto.

## 🦈 Passo 5: Inspeção Forense no Wireshark 

Como o arquivo .pcap foi gravado dentro da pasta /scripts, ele está disponível na máquina física em ./scripts/ataque_ddos.pcap. 

1. Abrir o arquivo no Wireshark
Execute no terminal da máquina física: 

```
wireshark ./scripts/ataque_ddos.pcap &
```


2. Filtros de Exibição Recomendados 

* Isolar requisições de abertura de conexão (SYN Flood):
Digite o filtro no topo da janela do Wireshark:

```
tcp.flags.syn == 1 && tcp.flags.ack == 0
```

* Análise de Falsificação de IPs:
Inspecione a coluna Source: repare como cada pacote possui um IP de origem aleatório e diferente, comprovando a técnica de IP Spoofing.

* Gráfico de Vazão I/O:
Acesse Statistics ➔ I/O Graphs no menu do Wireshark para visualizar a rampa exponencial no gráfico de pacotes por segundo.

## 🛡️ Passo 6: Mitigação com IPTABLES (Rate Limiting)
Para proteger a rede contra o ataque de SYN Flood, aplique uma regra de limitação de frequência (Rate Limit) na cadeia FORWARD do Firewall.

1. Aplicar a regra de proteção no Firewall
Execute no host:

```
# Permite apenas 10 requisições SYN por segundo e descarta o excesso
docker exec -it clab-lab01-firewall iptables -A FORWARD -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT
docker exec -it clab-lab01-firewall iptables -A FORWARD -p tcp --syn -j DROP
```

2. Disparar o ataque novamente
No terminal do atacante: 
```
docker exec -it clab-lab01-atacante hping3 --flood -S -p 80 --rand-source 192.168.20.10
``` 

3. Acompanhar a mitigação em tempo real
Em outro terminal no host, monitore as regras do iptables descartando o tráfego excedente:

```
docker exec -it clab-lab01-firewall watch -n 1 "iptables -L FORWARD -n -v --line-numbers"
```

#### Tabela de Resultado da Inspeção:

| num | pkts | bytes | target | prot | opt | in | out | source | destination | extra |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | 200 | 8000 | `ACCEPT` | tcp | -- | `*` | `*` | 0.0.0.0/0 | 0.0.0.0/0 | tcp flags:0x02/0x02 limit: avg 10/sec burst 20 |
| **2** | **145230** | **5809200** | `DROP` | tcp | -- | `*` | `*` | 0.0.0.0/0 | 0.0.0.0/0 | tcp flags:0x02/0x02 |

> **Conclusão:** O contador `pkts` da regra 2 (`DROP`) subirá de forma contínua, demonstrando que o Firewall está descartando a inundação maliciosa enquanto a estabilidade da rede do Cliente é restabelecida.


























