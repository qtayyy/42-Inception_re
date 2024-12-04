all:
	@docker compose -f ./srcs/compose.yaml up -d --build


clean:
	@docker stop $$(docker ps -qa); \
	docker rm $$(docker ps -qa); \
	docker rmi -f $$(docker images -qa); \
	docker volume rm $$(docker volume ls -q); \
	docker network rm $$(docker network ls -q)

.PHONY: all clean
