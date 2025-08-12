# Multi-stage Dockerfile for development and production builds

# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git

# Copy go mod files first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags "-s -w" -o mycli .

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk --no-cache add ca-certificates tzdata && \
    update-ca-certificates

# Create non-root user
RUN addgroup -g 1001 appgroup && \
    adduser -D -u 1001 -G appgroup appuser

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/mycli .

# Change ownership and make executable
RUN chown -R appuser:appgroup /app && \
    chmod +x mycli

# Switch to non-root user
USER appuser

# Add to PATH
ENV PATH="/app:${PATH}"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ./mycli --version > /dev/null || exit 1

# Expose port if needed
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["./mycli"]
CMD ["--help"]
