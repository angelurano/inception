NAME := inception
DOCKER_COMPOSE := docker compose -p $(NAME) -f srcs/docker-compose.yml

DATA_PATH ?= /home/migugar2/data
export DATA_PATH

all: up

build:
	@mkdir -p $(DATA_PATH)/mariadb $(DATA_PATH)/wordpress
	$(DOCKER_COMPOSE) build

up: build
	$(DOCKER_COMPOSE) up -d

down:
	$(DOCKER_COMPOSE) down

.PHONY: all build up down
