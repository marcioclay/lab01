#!/bin/bash

# Identifica o diretório do script (Laboratorio/laboratorio1/scripts) e a pasta do laboratório
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BRIDGE_NAME="switch"
CLAB_FILE="$PROJECT_DIR/topologia.yml"

echo "=== 1. Verificando a Bridge no sistema ==="
if ! ip link show "$BRIDGE_NAME" > /dev/null 2>&1; then
    echo "A bridge '$BRIDGE_NAME' não existe. Criando..."
    sudo ip link add name "$BRIDGE_NAME" type bridge
    sudo ip link set dev "$BRIDGE_NAME" up
    echo "Bridge '$BRIDGE_NAME' criada e ativada com sucesso."
else
    echo "A bridge '$BRIDGE_NAME' já existe. Garantindo que está ativa..."
    sudo ip link set dev "$BRIDGE_NAME" up
fi

echo ""
echo "=== 2. Iniciando Deploy da Topologia ($CLAB_FILE) ==="
sudo containerlab deploy -t "$CLAB_FILE"
