FROM golang:1.24.1-alpine AS builder 
WORKDIR /app 
COPY . . 
# Stelle sicher, dass das config-Verzeichnis existiert
RUN mkdir -p config
RUN go build -o bin/kormit cmd/kormit/main.go 
 
FROM alpine:3.15 
WORKDIR /app 
COPY --from=builder /app/bin/kormit /app/kormit 
COPY --from=builder /app/config /app/config 
EXPOSE 8080 
ENTRYPOINT ["/app/kormit"] 
