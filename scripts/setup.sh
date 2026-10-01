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
echo "=== 4. Ajustes Mínimos de Permissões de Sistema ==="
# Ajuste necessário apenas para o Zabbix conseguir disparar pings de monitoramento
docker exec -u 0 clab-lab01-zabbix chmod 4755 /usr/sbin/fping > /dev/null 2>&1 || true

echo ""
echo "=== ✅ Infraestrutura implantada com sucesso! ==="
echo "A topologia está ativa. Siga o roteiro prático para configurar o Roteamento e o Firewall."
echo ""
echo "Tabela de Endereçamento:"
echo " - Firewall: 192.168.10.1 (WAN) / 192.168.20.1 (LAN)"
echo " - Atacante: 192.168.10.10 (Rede Externa)"
echo " - Cliente:  192.168.20.10 (Rede Interna)"
echo " - Zabbix:   192.168.20.5  (Painel Web Host: http://localhost:8080)"
