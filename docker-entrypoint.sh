#!/bin/bash
set -e

echo "🔄 Verificando se o cliente Prisma precisa ser gerado..."

# Verificar se o cliente Prisma já foi gerado
if [ ! -d "/app/prisma/generated" ]; then
    echo "⚙️  Gerando cliente Prisma..."
    
    # Fazer fetch do Prisma CLI se necessário
    python -m prisma py fetch
    
    # Gerar o cliente Prisma
    python -m prisma generate
    
    # Ajustar permissões dos arquivos gerados
    chown -R appuser:appgroup /app/prisma/generated 2>/dev/null || true
    
    echo "✅ Cliente Prisma gerado com sucesso!"
else
    echo "✅ Cliente Prisma já existe!"
fi

echo "🚀 Iniciando aplicação como usuário não-root..."

# Mudar para usuário não-root e executar o comando
exec gosu appuser "$@"