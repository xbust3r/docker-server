.DEFAULT_GOAL := help

PROJECT_NAME = services
DOCKER_NETWORK = services_network


build: ## download all images
	docker pull mariadb:10.5.12
	docker pull tutum/mongodb:3.0
	docker pull redis:2.8
	docker pull dockercloud/haproxy:1.6.3
	make verify_network

up: ## start up the services
	@make verify_network &> /dev/null
	@make up_lb
	DOCKER_NETWORK=$(DOCKER_NETWORK) \
	PROJECT_NAME=$(PROJECT_NAME) \
	docker-compose -p ${PROJECT_NAME} up -d --remove-orphans

up_lb: ## start up the lb service
	@DOCKER_NETWORK=$(DOCKER_NETWORK) \
	docker-compose -f docker-compose.lb.yml up -d
	sh docker/lb/hook.sh&
	@make status

stop:
	@make verify_network &> /dev/null
	@make stop_lb
	DOCKER_NETWORK=$(DOCKER_NETWORK) \
	PROJECT_NAME=$(PROJECT_NAME) \
	docker-compose -p ${PROJECT_NAME} stop

stop_lb:
	@make verify_network &> /dev/null
	DOCKER_NETWORK=$(DOCKER_NETWORK) \
	docker-compose -f docker-compose.lb.yml stop

status:
	DOCKER_NETWORK=$(DOCKER_NETWORK) \
	PROJECT_NAME=$(PROJECT_NAME) \
	docker-compose -p $(PROJECT_NAME) ps

logs:
	DOCKER_NETWORK=$(DOCKER_NETWORK) \
	PROJECT_NAME=$(PROJECT_NAME) \
	docker-compose -p $(PROJECT_NAME) logs

verify_network:
	@if [ -z $$(docker network ls | grep $(DOCKER_NETWORK) | awk '{print $$2}') ]; then\
		(docker network create $(DOCKER_NETWORK));\
	fi

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'
