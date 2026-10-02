#!/bin/bash
# scripts/install_deps.sh - Executar Apenas 1 Vez em Máquinas Limpas

echo "=== 1. Instalando o Docker ==="
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    echo "Docker instalado com sucesso!"
else
    echo "Docker já está instalado."
fi

echo ""
echo "=== 2. Instalando o Containerlab ==="
if ! command -v containerlab &> /dev/null; then
    bash -c "$(curl -sL https://get.containerlab.dev)"
    echo "Containerlab instalado com sucesso!"
else
    echo "Containerlab já está instalado."
fi

echo ""
echo "=== ✅ Todos os pré-requisitos foram instalados! ==="
