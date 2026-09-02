# 📊 Configuração Simples do Zabbix (Monitoramento de Rede)

Guia passo a passo para cadastrar os ativos da topologia no Zabbix e monitorar a disponibilidade e latência da rede via checagem ICMP (Ping simples).

---

## 📋 Ativos a Serem Monitorados

O servidor Zabbix (`10.0.0.5`) fará a coleta dos dados diretamente nos endereços IPs dos containers da rede:

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

---

### 2. Criar o Grupo de Hosts
1. No menu superior, acesse **Configuration** > **Host groups**.
2. No **canto superior direito**, clique no botão azul **Create host group**.
3. No campo **Group name**, digite: `Lab01 - Rede Local`.
4. Clique no botão **Add** no rodapé da página.

---

### 3. Cadastrar os Dispositivos (Firewall, PC1, PC2 e PC3)

> ⚠️ **ATENÇÃO:** Não digite os dados nas caixas de texto no centro da tela de Hosts — elas servem apenas para **Filtrar/Buscar**. Para abrir o formulário de cadastro, você deve usar o botão azul no canto superior direito.

Para cada dispositivo (`firewall`, `pc1`, `pc2` e `pc3`), faça o seguinte:

1. Acesse **Configuration** > **Hosts** no menu superior.
2. Clique no botão azul **`Create host`** localizado no **canto superior direito da tela** (ao lado de *Import*).
3. Na aba **Host**, preencha os campos:
   * **Host name:** Nome do ativo (exemplo: `firewall` ou `pc1`).
   * **Groups:** Clique em **Select** do lado do campo, marque o grupo `Lab01 - Rede Local` e clique em **Select**.
   * **Interfaces:** Na seção *Interfaces*, clique em **Add** > **Agent**, selecione a opção **IP** e digite o IP correspondente (exemplo: `10.0.0.1` para o firewall).
4. Vincular o Template de Ping:
   * No campo **Templates**, clique em **Select**, busque por `Template Module ICMP Ping` (ou `Service - ICMP Ping`), selecione-o e clique em **Select**.
5. Clique no botão azul **Add** na parte inferior da tela para finalizar o cadastro.

---

## 📈 Visualizando o Comportamento da Rede

Após cadastrar os hosts, aguarde de 1 a 2 minutos para o Zabbix iniciar as coletas.

* **Status de Disponibilidade:** Acesse **Monitoring** > **Hosts**. Todos os equipamentos cadastrados devem exibir o status em verde na coluna de disponibilidade.
* **Gráficos de Latência e Perda de Pacotes:**
  1. Acesse **Monitoring** > **Latest data**.
  2. No filtro de grupos, selecione `Lab01 - Rede Local` e clique em **Apply**.
  3. Clique em **Graph** ao lado das métricas *ICMP response time* ou *ICMP loss* para ver os gráficos em tempo real.
