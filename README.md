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

## 2. Excluir todos os containers do host
```
   # 1. Destruir todas as topologias ativas registradas no Containerlab
   sudo containerlab destroy --all --cleanup 2>/dev/null || true
   
   # 2. Forçar a interrupção e remoção de TODOS os containers Docker no sistema
   sudo docker rm -f $(sudo docker ps -aq) 2>/dev/null || true
   
   # 3. Remover todas as redes virtuais e volumes órfãos do Docker
   sudo docker network prune -f
   sudo docker volume prune -f
   
   # 4. Apagar pontes de rede (bridges) que possam ter ficado presas no Kernel
   sudo ip link delete switch1 2>/dev/null || true
   sudo ip link delete switch2 2>/dev/null || true
   sudo ip link delete switch 2>/dev/null || true
   
   # 5. Apagar diretórios de estado, runtime e sockets do Containerlab e das pastas locais
   sudo rm -rf /etc/containerlab/
   sudo rm -rf /var/run/containerlab/
   sudo rm -rf /tmp/containerlab/
   sudo rm -rf ./clab-*/
   
   # 6. Encerrar qualquer processo do Containerlab pendente em memória
   sudo pkill -f containerlab 2>/dev/null || true
```

**Comando de Verificação**
Para confirmar que a limpeza foi total, execute estes dois comandos. Ambos devem retornar listas completamente vazias:
```
  # Deve retornar zero containers
   sudo docker ps -a

  # Deve retornar "no labs found"
   sudo containerlab inspect --all
```   

## 3. Clonar o repositório e preparar permissões:Executar no terminal do ambiente Linux.

Clone o repositório contendo a estrutura da pasta /lab e ajuste as permissões de execução do script:

```
git clone https://github.com/marcioclay/lab01.git
cd lab01
```
## 4. Implantar e testar a topologia: 
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


## 5. Mapeamento dos IPs dos hosts

Endereçamento configurado nas interfaces de rede divididas entre a sub-rede WAN (`192.168.10.0/24`) e LAN (`192.168.20.0/24`):

| **Contentor** | **Interface de Rede** | **Endereço IP** | **Rede / Segmento** | **Função na Topologia** |
|---|---|---|---|---|
| **firewall** | `eth1`<br>`eth2` | `192.168.10.1/24`<br>`192.168.20.1/24` | WAN (`switch1`)<br>LAN (`switch2`) | Gateway / Firewall / Router NAT |
| **atacante** | `eth1` | `192.168.10.10/24` | WAN (`switch1`) | Host Atacante (Gera tráfego DoS/DDoS via `hping3`) |
| **cliente** | `eth1` | `192.168.20.10/24` | LAN (`switch2`) | Estação de Trabalho Legítima / Alvo |
| **zabbix** | `eth1` | `192.168.20.5/24` | LAN (`switch2`) | Servidor de Monitorização All-in-One |


---

## 6. Testar conectividade entre os hosts: Validação do roteamento e redes virtuais

Realize os testes de conectividade ICMP (`ping`) entre as diferentes sub-redes para validar o roteamento e a comunicação através do firewall:

```
# 1. Testar comunicação da LAN: Cliente até o Gateway/Firewall (192.168.20.1)
docker exec -it clab-lab01-cliente ping -c 3 192.168.20.1

# 2. Testar acesso à Internet a partir do Cliente (via NAT no Firewall)
docker exec -it clab-lab01-cliente ping -c 3 8.8.8.8

# 3. Testar comunicação atravessando o Firewall: Atacante (WAN) até o Cliente (LAN)
docker exec -it clab-lab01-atacante ping -c 3 192.168.20.10

# 4. Testar comunicação interna: Zabbix até o Cliente
docker exec -it clab-lab01-zabbix ping -c 3 192.168.20.10

## 7. Testar o serviço e acessar o Zabbix: Verificação da porta HTTP e login.
Confirme se a interface web do Zabbix está respondendo na porta mapeada (8080):

```

## 9. Ver status do zabbix
```
docker ps -f name=clab-lab01-zabbix 
```
Acesse o painel pelo navegador em http://<IP-DA-MAQUINA-HOSPEDEIRA>:8080 com os acessos:

- Usuário: Admin

- Senha: zabbix


