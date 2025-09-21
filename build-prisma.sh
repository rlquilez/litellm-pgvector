#!/bin/bash
set -e

echo "🔄 Gerando cliente Prisma..."

# Verificar se o arquivo schema.prisma existe
if [ ! -f "prisma/schema.prisma" ]; then
    echo "❌ Erro: arquivo prisma/schema.prisma não encontrado"
    exit 1
fi

# Configurar DATABASE_URL temporária se não existir
if [ -z "$DATABASE_URL" ]; then
    export DATABASE_URL="postgresql://user:password@localhost:5432/dummy_db"
    echo "⚠️  Usando DATABASE_URL temporária para geração do cliente"
fi

# Tentar gerar o cliente Prisma
if python -m prisma generate; then
    echo "✅ Cliente Prisma gerado com sucesso"
else
    echo "❌ Falha na geração do cliente Prisma"
    echo "📋 Informações de debug:"
    echo "  - Python version: $(python --version)"
    echo "  - Prisma version: $(python -m prisma version 2>/dev/null || echo 'não disponível')"
    echo "  - Working directory: $(pwd)"
    echo "  - Schema file exists: $(test -f prisma/schema.prisma && echo 'sim' || echo 'não')"
    exit 1
fi