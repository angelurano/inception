NAME := inception
DOCKER_COMPOSE := docker compose -p $(NAME) -f srcs/docker-compose.yml

DATA_PATH ?= /home/migugar2/data 

all: up

build:
	@mkdir -p $(DATA_PATH)/mariadb
	$(DOCKER_COMPOSE) build

up: build
	$(DOCKER_COMPOSE) up -d

down:
	$(DOCKER_COMPOSE) down

.PHONY: all build up down
