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

# Copy Prisma schema first
COPY prisma/ ./prisma/

# Install Prisma CLI and generate client
RUN python -m prisma py fetch && \
    python -m prisma generate

# Copy rest of application code
COPY . .

# Stage 2: Runtime
FROM python:3.11-slim AS runtime

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# Copy only installed dependencies and generated Prisma client
COPY --from=builder /root/.local /root/.local

# Copy application files (including generated Prisma client)
COPY --from=builder /app .

# Create non-root user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -G appgroup -u 1001

# Change ownership of app directory and user's local packages
RUN chown -R appuser:appgroup /app && \
    chown -R appuser:appgroup /root/.local

# Switch to non-root user
USER appuser

# Set PATH for the non-root user
ENV PATH=/root/.local/bin:$PATH

# Expose port
EXPOSE 8000

# Command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
