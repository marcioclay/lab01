# 🔍 Laboratório Prático: Reconhecimento de Rede (Port Scanning) e Bloqueio com IPTABLES

Este guia traz o passo a passo para a execução da prática de **mapeamento de rede e identificação de serviços (*Port Scanning*)** utilizando o `nmap`, seguido pela implementação de **regras de mitigação no `iptables`** contra varreduras furtivas e de força bruta.

---

## 📌 Topologia e Mapeamento de Testes

* **Atacante (WAN):** `192.168.10.10`
* **Firewall (Gateway):** `192.168.10.1` (WAN / `eth1`) e `192.168.20.1` (LAN / `eth2`)
* **Cliente / Alvo (LAN):** `192.168.20.10`
* **Zabbix / Alvo (LAN):** `192.168.20.5`

---

### Configurações iniciais
```
# Instalar iptables
docker exec -it clab-lab01-firewall apk add iptables
```

```
# Instalar nmap
docker exec -it clab-lab01-firewall apk add nmap
docker exec -it clab-lab01-atacante apk add nmap
```


```
# 1. Criar o grupo docker (caso ainda não exista)
sudo groupadd docker

# 2. Adicionar o usuário atual ao grupo docker
sudo usermod -aG docker $USER

# 3. Aplicar a alteração do grupo na sessão atual do terminal
newgrp docker
```


## 🎯 Módulo 1: Executando as Táticas de Reconhecimento (`nmap`)

Nesta etapa, o nó `atacante` executará diferentes modalidades de varredura contra os hosts da rede interna e a interface externa do Firewall.

### 1. SYN Scan / Stealth Scan (`-sS`)
Varredura padrão e furtiva que não finaliza o *handshake* TCP (envia um `SYN` e, ao receber `SYN-ACK`, responde com `RST` em vez de `ACK`).

```
# Instalar Nmap no container atacante
docker exec -it clab-lab01-atacante apk add nmap
```

```
docker exec -it clab-lab01-atacante nmap -sS 192.168.20.10
```


### 2. Connect Scan (-sT)
Varredura completa de Camada 4. Estabelece a conexão TCP completa (SYN ➔ SYN-ACK ➔ ACK), sendo facilmente registrada por logs de aplicação.
```
docker exec -it clab-lab01-atacante nmap -sT 192.168.20.10
```

### 3. Xmas Tree Scan (-sX) e NULL Scan (-sN)
Técnicas avançadas de evasão que manipulam flags do cabeçalho TCP para burlar firewalls simples (Stateless):

Xmas Scan: Ativa as flags FIN, URG e PSH simultaneamente (pacote "aceso como uma árvore de natal").

NULL Scan: Envia pacotes sem nenhuma flag TCP ativada
```
# Executar Xmas Scan contra o Cliente
docker exec -it clab-lab01-atacante nmap -sX 192.168.20.10

# Executar NULL Scan contra o Firewall
docker exec -it clab-lab01-atacante nmap -sN 192.168.10.1
```

### 4. UDP Scan (-sU)
Mapeia portas baseadas no protocolo UDP (ex: DNS, SNMP, DHCP).

```
docker exec -it clab-lab01-atacante nmap -sU -p 53,67,161 192.168.20.10
```

👁️ Módulo 2: Visualizando o Port Scan no Firewall (tcpdump)
Para entender o comportamento do pacotes durante a varredura, abra um terminal no host e observe as flags chegando na interface externa do Firewall (eth1):

```
#Terminal 1
docker exec -it clab-lab01-firewall tcpdump -i eth1 -n "tcp[tcpflags] & (tcp-syn|tcp-fin|tcp-push|tcp-urg) != 0"
```
```
#Terminal 2
docker exec -it clab-lab01-atacante nmap -sX 192.168.20.10
```
Cada campo da saída do `tcpdump` representa um elemento do cabeçalho do pacote capturado:

- **`12:18:12.673159` — Timestamp:** Horário exato em que o pacote foi capturado pela interface de rede (Horas:Minutos:Segundos.Microssegundos).

- **`IP` — Protocolo de Rede:** Indica que o pacote utiliza o protocolo IPv4.

- **`192.168.10.10.44232` — Origem (IP:Porta):** Endereço IP de origem (`192.168.10.10`), seguido da porta TCP de origem aleatória utilizada pelo cliente (`44232`).

- **`>` — Direção do Fluxo:** Símbolo que indica o sentido da comunicação (Origem → Destino).

- **`192.168.20.10.8194` — Destino (IP:Porta):** Endereço IP do alvo (`192.168.20.10`), seguido da porta TCP de destino varrida (`8194`).

- **`Flags [FPU]` — Flags TCP Ativas:** Mostra as *flags* marcadas no cabeçalho TCP:
  - **`F` (FIN):** Solicita a finalização da conexão.
  - **`P` (PSH / Push):** Força a entrega dos dados diretamente à aplicação, sem aguardar o preenchimento do *buffer*.
  - **`U` (URG / Urgent):** Sinaliza a existência de dados prioritários.

  *A combinação simultânea de `FIN`, `PSH` e `URG` caracteriza o padrão de um **Xmas Tree Scan** do Nmap.*

- **`seq 289253703` — Número de Sequência (Sequence Number):** Identificador do primeiro byte de dados enviado nesta transmissão TCP.

- **`win 1024` — Tamanho da Janela (Window Size):** Espaço disponível no *buffer* de recepção do transmissor, expresso em bytes.

- **`urg 0` — Ponteiro Urgente (Urgent Pointer):** Deslocamento relativo para os dados marcados como urgentes (0 indica ausência de dados extras).

- **`length 0` — Tamanho do Payload:** Quantidade de bytes de dados de aplicação transportados (0 indica que o pacote contém apenas os cabeçalhos, sem conteúdo de aplicação, típico de varreduras).


O que observar: Durante o Xmas Scan, o tcpdump exibirá pacotes com as flags [FPU] (FIN, PSH, URG), que não possuem uso legítimo em comunicações normais de rede.
---

🛡️ Módulo 3: Mitigação e Bloqueio de Scans com IPTABLES
No container firewall, aplicaremos regras na cadeia FORWARD para interceptar combinações inválidas de flags TCP e controlar a taxa de abertura de conexões (Port Scan Detector).

1. Bloqueio de Combinações Maliciosas de Flags TCP (Evasão)
Execute os comandos a seguir no terminal do host:

```
# A. Bloquear Xmas Scan (FIN, PSH, URG simultâneos)
docker exec -it clab-lab01-firewall iptables -A FORWARD -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP

# B. Bloquear NULL Scan (Nenhuma flag ativa)
docker exec -it clab-lab01-firewall iptables -A FORWARD -p tcp --tcp-flags ALL NONE -j DROP

# C. Bloquear SYN e FIN simultâneos (Anomalia de protocolo)
docker exec -it clab-lab01-firewall iptables -A FORWARD -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP

# D. Bloquear SYN e RST simultâneos
docker exec -it clab-lab01-firewall iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
```

2. Bloqueio Dinâmico de Port Scan por Frequência (Módulo recent)
Para detectar e bloquear atacantes que tentam escanear centenas de portas em curto intervalo de tempo, utilize o módulo recent do iptables:
```
sudo chmod 666 /var/run/docker.sock
```

A. Criar a Regra de Log no Firewall
Execute no host para adicionar a regra de log antes de contabilizar ou bloquear:
```
docker exec -it clab-lab01-firewall iptables -I FORWARD -p tcp --syn -m recent --update --seconds 10 --hitcount 15 --name PORTSCAN -j LOG --log-prefix "[PORTSCAN DETECTADO] "
```

B. Redirecionar os Logs em Tempo Real para o Arquivo
Execute no host o comando que monitora os logs do Kernel no container e grava continuamente dentro do volume compartilhado /scripts/portscan.log:
```
docker exec -d clab-lab01-firewall sh -c "dmesg -w | grep --line-buffered 'PORTSCAN DETECTADO' >> /scripts/portscan.log"
```
C. Acompanhar os Eventos na Tela (no Host)
Para visualizar os alertas surgindo na tela enquanto eles são salvos no arquivo, abra um terminal na máquina host (pasta /lab01) e rode:
```
tail -f ./scripts/portscan.log
```

🧪 Testando o Fluxo
Deixe o * tail -f ./scripts/portscan.log * aberto no Terminal 1.

No Terminal 2, dispare a varredura a partir do atacante:
```
docker exec -it clab-lab01-atacante nmap -sS -p 1-100 192.168.20.10
```

Resultado: As entradas aparecerão em tempo real no Terminal 1 e o arquivo ./scripts/portscan.log ficará gravado no seu disco com o seguinte formato: 
```
[PORTSCAN DETECTADO] IN=eth1 OUT=eth2 MAC=... SRC=192.168.10.10 DST=192.168.20.10 LEN=40 TOS=0x00 TTL=63 ID=42891 PROTO=TCP SPT=43892 DPT=80 WINDOW=1024 SYN
```





---
🧪 Módulo 4: Validação do Bloqueio
1. Disparar o Port Scan novamente a partir do atacante:

   ```
   docker exec -it clab-lab01-atacante nmap -sS -p 1-100 192.168.20.10
   ```

2. Verificar os contadores de bloqueio em tempo real no Firewall:

```
docker exec -it clab-lab01-firewall watch -n 1 "iptables -L FORWARD -n -v --line-numbers"
```




