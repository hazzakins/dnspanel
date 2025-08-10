# Makefile for Docker & Docker Compose workflow

# Variables
DOCKER_COMPOSE_FILE := docker-compose.yml
DOCKER_IMAGE := dnspanel
DOCKER_TAG := latest
# Default target
.PHONY: build
build:
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

.PHONY: up
up:
	docker compose -f $(DOCKER_COMPOSE_FILE) up -d

.PHONY: down
down:
	docker compose -f $(DOCKER_COMPOSE_FILE) down

.PHONY: clear-cache
clear-cache:
	docker builder prune -af
	docker image prune -af

.PHONY: test
test: down build up
