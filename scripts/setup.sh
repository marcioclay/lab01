#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BRIDGES=("switch1" "switch2")
CLAB_FILE="$PROJECT_DIR/topologia.yml"

echo "=== 1. Limpando execuções e estados anteriores ==="
sudo containerlab destroy -t "$CLAB_FILE" --cleanup > /dev/null 2>&1 || true

echo ""
echo "=== 2. Criando e ativando as Bridges Linux ('switch1' e 'switch2') ==="
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
echo "=== 3. Executando Deploy da Topologia no Containerlab ==="
sudo containerlab deploy -t "$CLAB_FILE"

echo ""
echo "=== 4. Aplicando Configurações de Roteamento, Firewall e Permissões ==="
echo "Aguardando inicialização dos containers..."
sleep 3

# 4.1. Habilitar Roteamento no Firewall
echo "[Firewall] Habilitando ip_forward..."
docker exec clab-lab01-firewall sysctl -w net.ipv4.ip_forward=1 > /dev/null

# 4.2. Configurar NAT / Masquerade para saída da LAN em direção à Internet (eth0)
echo "[Firewall] Configurando NAT/Masquerade via eth0..."
docker exec clab-lab01-firewall iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# 4.3. Regras de FORWARD Stateful para permitir navegação da LAN (eth2 -> eth0)
echo "[Firewall] Configurando regras de repasse FORWARD de Internet..."
docker exec clab-lab01-firewall iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
docker exec clab-lab01-firewall iptables -A FORWARD -i eth0 -o eth2 -m state --state ESTABLISHED,RELATED -j ACCEPT

# 4.4. Permissões de fping no Zabbix
echo "[Zabbix] Ajustando permissões do fping para monitoramento ICMP..."
docker exec -u 0 clab-lab01-zabbix chmod 4755 /usr/sbin/fping > /dev/null 2>&1 || true

echo ""
echo "=== ✅ Laboratório implantado com sucesso! ==="
echo "Tabela de Endereçamento:"
echo " - Firewall: 192.168.10.1 (WAN) / 192.168.20.1 (LAN)"
echo " - Atacante: 192.168.10.10 (Rede Externa)"
echo " - Cliente:  192.168.20.10 (Rede Interna)"
echo " - Zabbix:   192.168.20.5  (Acesso LAN: http://192.168.20.5 / Host: http://localhost:8080)"
