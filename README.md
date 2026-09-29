# lab-01 — Topologia Containerlab para Testes  

Laboratório containerlab para  mitigação de ataque DoS usando iptables e zabix como monitor de observabilidade. 

[![Containerlab](https://img.shields.io/badge/Containerlab-v0.50+-blue?logo=linux)](https://containerlab.dev)
[![Docker](https://img.shields.io/badge/Docker-required-blue?logo=docker)](https://www.docker.com)
[![Licença](https://img.shields.io/badge/licença-GPL--2.0-green)](LICENSE)
---

## 1. Visão geral da topologia
``` text
 REDE EXTERNA (WAN) — Subnet 192.168.10.0/24
     ┌──────────────────────────────────────────────────────────────────┐
     │                Switch Virtual 1 (switch1 / bridge)               │
     └─────────────┬──────────────────────────────────────┬─────────────┘
                   │ switch1:eth1                         │ switch1:eth2
                   ▼                                      ▼
         ┌───────────────────┐                  ┌───────────────────┐
         │     atacante      │                  │     firewall      │
         │  (192.168.10.10)  │                  │  (192.168.10.1)   │
         │       eth1        │                  │       eth1        │
         └───────────────────┘                  └─────────┬─────────┘
                                                          │ eth2
                                                          │ (192.168.20.1)
                                                          ▼
     ┌──────────────────────────────────────────────────────────────────┐
     │                Switch Virtual 2 (switch2 / bridge)               │
     └─────────────┬──────────────────────────────────────┬─────────────┘
                   │ switch2:eth2                         │ switch2:eth3
                   ▼                                      ▼
         ┌───────────────────┐                  ┌───────────────────┐
         │      cliente      │                  │      zabbix       │
         │  (192.168.20.10)  │                  │   (192.168.20.5)  │
         │       eth1        │                  │       eth1        │
         └───────────────────┘                  └───────────────────┘
                  REDE INTERNA (LAN) — Subnet 192.168.20.0/24
       
```


## 2. Clonar o repositório e preparar permissões:Executar no terminal do ambiente Linux.

Clone o repositório contendo a estrutura da pasta /lab e ajuste as permissões de execução do script:

```
git clone https://github.com/marcioclay/lab01.git
cd lab01
```
## 3. Implantar e testar a topologia: 
Criação da bridge e subida dos containers.
Execute o script de automação a partir do diretório /lab para criar a bridge switch e realizar o deploy: 

```
chmod +x scripts/setup.sh
./scripts/setup.sh
```

## 4. Teste de Acesso à Internet do Cliente
Confirme se o cliente acessa a rede externa passando pelo NAT do firewall:

``` 
docker exec -it clab-lab01-cliente ping -c 3 8.8.8.8
```

## 5. Simulação de Ataque do Atacante contra o Cliente

Do container atacante, inunde o cliente passando pelo firewall:
```
docker exec -it clab-lab01-atacante hping3 --flood -S -p 80 192.168.20.10
```

## 6. Bloqueio no Firewall (Cadeia FORWARD)
No firewall, bloqueie o tráfego do atacante em direção à rede interna:

```
# Regra no firewall para barrar o IP do atacante atravessando a rede
docker exec -it clab-lab01-firewall iptables -A FORWARD -s 192.168.10.10 -j DROP

# Monitorar os contadores de bloqueio subindo em tempo real
docker exec -it clab-lab01-firewall watch -n 1 "iptables -L FORWARD -n -v"
```



## 7. Mapeamento dos IPs dos hosts

Endereçamento configurado nas interfaces de rede divididas entre a sub-rede WAN (`192.168.10.0/24`) e LAN (`192.168.20.0/24`):

| **Contentor** | **Interface de Rede** | **Endereço IP** | **Rede / Segmento** | **Função na Topologia** |
|---|---|---|---|---|
| **firewall** | `eth1`<br>`eth2` | `192.168.10.1/24`<br>`192.168.20.1/24` | WAN (`switch1`)<br>LAN (`switch2`) | Gateway / Firewall / Router NAT |
| **atacante** | `eth1` | `192.168.10.10/24` | WAN (`switch1`) | Host Atacante (Gera tráfego DoS/DDoS via `hping3`) |
| **cliente** | `eth1` | `192.168.20.10/24` | LAN (`switch2`) | Estação de Trabalho Legítima / Alvo |
| **zabbix** | `eth1` | `192.168.20.5/24` | LAN (`switch2`) | Servidor de Monitorização All-in-One |

## 6. Testar conectividade entre os hosts: Validação do tráfego através do switch virtual.
Realize testes de conectividade ICMP (ping) entre diferentes pontos da rede:
```
# 1. Testar comunicação do PC1 até o Firewall
docker exec -it clab-lab01-pc1 ping -c 3 10.0.0.1

# 2. Testar comunicação do Zabbix até o PC1, PC2 e PC3
docker exec -it clab-lab01-zabbix ping -c 3 10.0.0.2
docker exec -it clab-lab01-zabbix ping -c 3 10.0.0.3
docker exec -it clab-lab01-zabbix ping -c 3 10.0.0.4
```

## 7. Testar o serviço e acessar o Zabbix: Verificação da porta HTTP e login.
Confirme se a interface web do Zabbix está respondendo na porta mapeada (8080):

```
# Ver status do zabbix
docker ps -f name=clab-lab01-zabbix 
```
```
curl -I http://localhost:8080
```

Acesse o painel pelo navegador em http://<IP-DA-MAQUINA-HOSPEDEIRA>:8080 com os acessos:

- Usuário: Admin

- Senha: zabbix


