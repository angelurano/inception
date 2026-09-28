NAME := inception
DOCKER_COMPOSE := docker compose -p $(NAME) -f srcs/docker-compose.yml

DATA_PATH ?= /home/migugar2/data 

all: build up

up: 
	$(DOCKER_COMPOSE) up -d

build:
	$(DOCKER_COMPOSE) build

down:
	$(DOCKER_COMPOSE) down

.PHONY: all build up down
