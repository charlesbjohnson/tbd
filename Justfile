default:
	@just --list

build:
	@go mod tidy
	@go build -o bin/tbd cmd/tbd/main.go

clean:
	@rm -rf bin

run:
	@go mod tidy
	@go run cmd/tbd/main.go

fmt:
	@go mod edit -fmt go.mod
	@go fmt ./...

lint:
	@golangci-lint run ./...
