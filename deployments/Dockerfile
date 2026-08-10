# Build stage
FROM golang:1.26.4-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/navgo ./cmd/server \
 && CGO_ENABLED=0 GOOS=linux go build -o /bin/navgo-mcp ./cmd/mcp

# Runtime stage
FROM alpine:3.24

RUN apk add --no-cache ca-certificates tzdata \
 && addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /bin/navgo /app/navgo
COPY --from=builder /bin/navgo-mcp /app/navgo-mcp
COPY --from=builder /app/internal/infrastructure/postgres/migrations /app/migrations

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

ENTRYPOINT ["/app/navgo"]
