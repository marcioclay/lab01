# 🚀 Tutorial: Entendendo e Executando o Script `setup.sh`

Este guia explica o funcionamento do script `scripts/setup.sh`, responsável pela automação e criação da infraestrutura do laboratório de cibersegurança no **Containerlab**.

---

## 🛠️ O que o `setup.sh` faz (Passo a Passo)

O script divide a preparação da infraestrutura em 4 etapas automáticas:

### 1. Limpeza de Instâncias Anteriores
Executa a destruição preventiva de execuções prévias da topologia (`lab01`). Isso previne conflitos de nomes de contentores, portas alocadas e sockets pendentes do Containerlab.

### 2. Criação das Bridges Virtuais (`switch1` e `switch2`)
O script verifica no Kernel do Linux se os comutadores virtuais (*bridges*) `switch1` (WAN) e `switch2` (LAN) existem. Caso não existam, o script cria-os e ativa-os (`ip link set dev ... up`).

### 3. Deploy da Topologia via Containerlab
Dispara o comando de implantação apontando para o ficheiro `topologia.yml`. Nesta etapa, os contentores `firewall`, `atacante`, `cliente` e `zabbix` são descarregados, iniciados e interligados às respetivas *bridges*.

### 4. Ajustes Mínimos de Permissão
Aplica o bit SUID no binário `/usr/sbin/fping` dentro do contentor `zabbix` (`chmod 4755`). Isto é necessário para que o serviço do Zabbix consiga enviar pacotes ICMP sem restrições de permissão.

> **Nota:** As configurações de roteamento (`ip_forward`), NAT e regras de firewall foram removidas do `setup.sh` para que sejam executadas manualmente pelos alunos como exercício prático.

---

## 📋 Como Executar no Terminal

Navegue até à raiz do repositório, atribua permissão de execução e inicie a automação:

```bash
# 1. Conceder permissão de execução
chmod +x scripts/setup.sh

# 2. Executar o script de implantação
./scripts/setup.sh
