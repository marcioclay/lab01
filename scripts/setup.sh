#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BRIDGES=("switch1" "switch2")
CLAB_FILE="$PROJECT_DIR/topologia.yml"

echo "=== 1. Criando e ativando as Bridges Linux ('switch1' e 'switch2') ==="
for BRIDGE in "${BRIDGES[@]}"; do
    if ! ip link show "$BRIDGE" > /dev/null 2>&1; then
        echo "A bridge '$BRIDGE' não existe. Criando..."
        sudo ip link add name "$BRIDGE" type bridge
        sudo ip link set dev "$BRIDGE" up
        echo "Bridge '$BRIDGE' criada com sucesso."
    else
        echo "A bridge '$BRIDGE' já existe. Garantindo estado ativo..."
        sudo ip link set dev "$BRIDGE" up
    fi
done

echo ""
echo "=== 2. Executando Deploy da Topologia no Containerlab ==="
sudo containerlab deploy -t "$CLAB_FILE"

echo ""
echo "=== 3. Aplicando Configurações de Roteamento e Permissões ==="

# Aguarda 3 segundos para garantir que os sistemas operacionais dos containers inicializaram as interfaces
echo "Aguardando inicialização dos serviços internos..."
sleep 3

# 3.1. Habilitar Roteamento no Firewall
echo "[Firewall] Habilitando ip_forward..."
docker exec clab-lab01-firewall sysctl -w net.ipv4.ip_forward=1 > /dev/null

# 3.2. Configurar NAT no Firewall para dar acesso à Internet para o Cliente
echo "[Firewall] Configurando NAT/Masquerade para saída de Internet via eth0..."
docker exec clab-lab01-firewall iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# 3.3. Permissões de fping no Zabbix
echo "[Zabbix] Ajustando permissões do fping para monitoramento ICMP..."
docker exec -u 0 clab-lab01-zabbix chmod 4755 /usr/sbin/fping > /dev/null 2>&1 || true

echo ""
echo "=== ✅ Laboratório implantado com sucesso! ==="
echo "Tabela de Endereçamento:"
echo " - Firewall: 192.168.10.1 (WAN) / 192.168.20.1 (LAN)"
echo " - Atacante: 192.168.10.10 (Rede Externa)"
echo " - Cliente:  192.168.20.10 (Rede Interna)"
echo " - Zabbix:   192.168.20.5  (Painel Web: http://localhost:8080)"
