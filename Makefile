all: build start

build:
	@docker compose -f ./srcs/compose.yaml build

start:
	@docker compose -f ./srcs/compose.yaml up -d

stop:
	@docker compose -f ./srcs/compose.yaml stop

down:
	@docker compose -f ./srcs/compose.yaml down

logs:
	@docker compose -f ./srcs/compose.yaml logs -f

# Add this to ease eval
clean:
	@docker stop $$(docker ps -qa) 2>/dev/null; \
	docker rm $$(docker ps -qa) 2>/dev/null; \
	docker rmi -f $$(docker images -qa) 2>/dev/null; \
	docker volume rm $$(docker volume ls -q) 2>/dev/null; \
	docker network rm $$(docker network ls -q) 2>/dev/null

prune:
	@docker system prune -af --volumes

re: clean all

.PHONY: all build start stop restart logs clean prune re
