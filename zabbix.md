# lab-01 — Configuração   

Laboratório containerlab para  mitigação de ataque DoS usando iptables e zabix como monitor de observabilidade. 

[![Containerlab](https://img.shields.io/badge/Containerlab-v0.50+-blue?style=for-the-badge&logo=linux&logoColor=white)](https://containerlab.dev)
[![Docker](https://img.shields.io/badge/Docker-required-blue?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com)
[![Licença](https://img.shields.io/badge/licença-GPL--2.0-green?style=for-the-badge)](LICENSE)
![Zabbix](https://img.shields.io/badge/Zabbix-D40000?style=for-the-badge&logo=zabbix&logoColor=white)
![iptables](https://img.shields.io/badge/iptables-Firewall-E65100?style=for-the-badge&logo=linux&logoColor=white)
---

# 📊 Configuração Simples do Zabbix (Monitoramento de Rede)

Guia passo a passo para cadastrar os ativos da topologia no Zabbix e monitorar a disponibilidade e latência da rede via checagem ICMP (Ping simples).

---

## 📋 Ativos a Serem Monitorados

O servidor Zabbix (`10.0.0.5`) realizará a coleta dos dados diretamente na interface interna dos dispositivos cadastrados:

| Host | IP na Topologia | Tipo de Monitoramento |
| :--- | :--- | :--- |
| **firewall** | `10.0.0.1` | Checagem Simples (ICMP Ping) |
| **pc1** | `10.0.0.2` | Checagem Simples (ICMP Ping) |
| **pc2** | `10.0.0.3` | Checagem Simples (ICMP Ping) |
| **pc3** | `10.0.0.4` | Checagem Simples (ICMP Ping) |

---

## 🚀 Passo a Passo no Painel Web

### 1. Acesso Inicial
1. Acesse o painel pelo navegador: `http://<IP-DO-SERVIDOR>:8080`
2. Faça login com as credenciais padrão:
   * **Usuário:** `Admin` *(com 'A' maiúsculo)*
   * **Senha:** `zabbix`

### 2. Criar um Grupo de Hosts (Organização)
1. No menu esquerdo, acesse **Configuration** > **Host groups** (ou *Configuração* > *Grupos de hosts*).
2. Clique no botão **Create host group** (no canto superior direito).
3. No campo **Group name**, digite: `Lab01 - Rede Local`.
4. Clique em **Add**.

### 3. Cadastrar os Dispositivos
Para cada ativo da tabela (`firewall`, `pc1`, `pc2` e `pc3`), siga o procedimento abaixo:

1. Acesse **Configuration** > **Hosts** e clique em **Create host**.
2. Na aba **Host**, preencha:
   * **Host name:** Nome do ativo (exemplo: `pc1`).
   * **Templates:** Busque e selecione o template **`ICMP Ping`** (ou `Service - ICMP Ping`).
   * **Host groups:** Selecione o grupo criado (`Lab01 - Rede Local`).
   * **Interfaces:** Clique em **Add** > **Agent**, selecione **IP** e digite o endereço correspondente (exemplo: `10.0.0.2` para o `pc1`).
3. Clique em **Add** para salvar.

---

## 📈 Visualizando o Comportamento da Rede

Após cadastrar os hosts, o Zabbix começará a disparar pings a cada 1 minuto.

* **Status de Disponibilidade:** Acesse **Monitoring** > **Hosts**. Todos os hosts cadastrados devem listar o status em verde.
* **Gráficos de Latência e Perda de Pacotes:**
  1. Vá em **Monitoring** > **Latest data** (Dados recentes).
  2. Filtre pelo grupo `Lab01 - Rede Local`.
  3. Clique em **Graph** ao lado das métricas *ICMP response time* (tempo de resposta) ou *ICMP loss* (perda de pacotes) para acompanhar o comportamento em tempo real.
