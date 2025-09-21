# Stage 1: Builder
FROM python:3.11-alpine AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
# Set a dummy DATABASE_URL for Prisma generation
ENV DATABASE_URL="postgresql://user:password@localhost:5432/dummy_db"

WORKDIR /app

# Install build dependencies including Node.js for Prisma
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    musl-dev \
    libffi-dev \
    postgresql-dev \
    curl \
    bash \
    nodejs \
    npm

# Copy only requirements for caching
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Make build script executable and run Prisma generation
RUN chmod +x build-prisma.sh && ./build-prisma.sh

# Stage 2: Runtime
FROM python:3.11-alpine AS runtime

WORKDIR /app

# Install runtime dependencies only
RUN apk add --no-cache \
    postgresql-client \
    libpq

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
