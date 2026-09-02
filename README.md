# lab-01 — Topologia Containerlab para Testes  

Laboratório containerlab para  mitigação de ataque DoS usando iptables e zabix como monitor de observabilidade. 

[![Containerlab](https://img.shields.io/badge/Containerlab-v0.50+-blue?logo=linux)](https://containerlab.dev)
[![Docker](https://img.shields.io/badge/Docker-required-blue?logo=docker)](https://www.docker.com)
[![Licença](https://img.shields.io/badge/licença-GPL--2.0-green)](LICENSE)
---

## 1. Visão geral da topologia

 <img width="450" height="350" alt="image" src="https://github.com/user-attachments/assets/2026ee45-e2d1-4484-9ff3-f01471b04c07" />
       



## 2. Clonar o repositório e preparar permissões:Executar no terminal do ambiente Linux.

Clone o repositório contendo a estrutura da pasta /lab e ajuste as permissões de execução do script:

```
# 1. Clona a estrutura do repositório
git clone --filter=blob:none --sparse https://github.com/marcioclay/Seguranca_Redes-CEET.git

# 2. Entra no diretório e baixa apenas a pasta do laboratorio1
cd Seguranca_Redes-CEET
git sparse-checkout set "Laboratorio/laboratorio1"

# 3. Acesse a pasta e execute o setup
cd Laboratorio/laboratorio1
chmod +x scripts/setup.sh
./scripts/setup.sh
```
## 3. Implantar e testar a topologia: 
Criação da bridge e subida dos containers.
Execute o script de automação a partir do diretório /lab para criar a bridge switch e realizar o deploy: 

```
./scripts/setup.sh
```

## 4. Para validar se todos os containers foram iniciados corretamente pelo Containerlab, execute:

``` 
sudo containerlab inspect -t lab.clab.yml
```

## 5. Mapeamento dos IPs dos hosts:
Endereçamento configurado nas interfaces eth1.
Abaixo está a tabela com os endereços de rede configurados na subnet 10.0.0.0/24:

| **Container** | **Interface Interna** | **Endereço IP** | **Função na Topologia** |
|---|---|---|---|
| **firewall** | `eth1` | `10.0.0.1/24` | Gateway / Firewall |
| **pc1** | `eth1` | `10.0.0.2/24` | Estação de Trabalho |
| **pc2** | `eth1` | `10.0.0.3/24` | Estação de Trabalho |
| **pc3** | `eth1` | `10.0.0.4/24` | Estação de Trabalho |
| **zabbix** | `eth1` | `10.0.0.5/24` | Servidor de Monitoramento All-in-One | 

## 6. Testar conectividade entre os hosts: Validação do tráfego através do switch virtual.
Realize testes de conectividade ICMP (ping) entre diferentes pontos da rede:
```
# 1. Testar comunicação do PC1 até o Firewall
docker exec -it clab-lab-pc1 ping -c 3 10.0.0.1

# 2. Testar comunicação do Zabbix até o PC1, PC2 e PC3
docker exec -it clab-lab-zabbix ping -c 3 10.0.0.2
docker exec -it clab-lab-zabbix ping -c 3 10.0.0.3
docker exec -it clab-lab-zabbix ping -c 3 10.0.0.4
```

## 7. Testar o serviço e acessar o Zabbix: Verificação da porta HTTP e login.
Confirme se a interface web do Zabbix está respondendo na porta mapeada (8080):

```
curl -I http://localhost:8080
```

Acesse o painel pelo navegador em http://<IP-DA-MAQUINA-HOSPEDEIRA>:8080 com os acessos:

- Usuário: Admin

- Senha: zabbix


