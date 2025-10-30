#!/bin/bash
set -e

echo "Running linter..."
golangci-lint run

echo "Running unit tests..."
go test -v -race -coverprofile=coverage.txt -covermode=atomic ./...

echo "Coverage summary:"
go tool cover -func=coverage.txt | tail -n 1
