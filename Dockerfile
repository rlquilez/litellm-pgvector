# Stage 1: Builder
FROM python:3.11-alpine AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

WORKDIR /app

# Install build dependencies
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

# Generate Prisma client
RUN npx prisma generate

# Stage 2: Runtime
FROM python:3.11-alpine AS runtime

WORKDIR /app

# Copy only installed dependencies
COPY --from=builder /root/.local /root/.local
ENV PATH=/root/.local/bin:$PATH

# Copy application files
COPY --from=builder /app .

# Expose port
EXPOSE 8000

# Command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
