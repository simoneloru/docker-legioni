.PHONY: build run clean down

build:
	docker compose build

run:
	docker compose run --rm dev

clean:
	docker compose down -v

down:
	docker compose down
