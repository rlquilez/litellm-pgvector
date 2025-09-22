# Stage 1: Builder
FROM python:3.11-slim AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
# Set a dummy DATABASE_URL for Prisma generation
ENV DATABASE_URL="postgresql://user:password@localhost:5432/dummy_db"

WORKDIR /app

# Install build dependencies for Prisma and PostgreSQL
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    curl \
    git \
    openssl \
    ca-certificates \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements for caching
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Copy Prisma schema and application code
COPY . .

# Clean up build dependencies to reduce layer size
RUN apt-get purge -y \
    gcc \
    git \
    curl \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

# Stage 2: Runtime (Alpine para menor tamanho)
FROM python:3.11-alpine AS runtime

WORKDIR /app

# Install runtime dependencies only (minimal Alpine)
RUN apk add --no-cache \
    libpq \
    nodejs \
    su-exec \
    bash

# Copy only installed dependencies and generated Prisma client
COPY --from=builder /root/.local /root/.local

# Copy application files (including generated Prisma client)
COPY --from=builder /app .

# Make entrypoint script executable
RUN chmod +x docker-entrypoint.sh

# Create non-root user for security (Alpine syntax)
RUN addgroup -g 1001 -S appgroup && \
    adduser -S -u 1001 -G appgroup appuser

# Change ownership of app directory and user's local packages
RUN chown -R appuser:appgroup /app && \
    chown -R appuser:appgroup /root/.local

# Set PATH for the non-root user
ENV PATH=/root/.local/bin:$PATH

# Expose port
EXPOSE 8000

# Set entrypoint and command (run as root to generate Prisma, then switch user)
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
