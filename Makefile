SHELL := /bin/bash

build:
	mvn clean package
	podman build -t mi-test:latest . --no-cache

run-compose:
	/bin/bash -c 'export $$(cat .env | xargs) >/dev/null; envsubst < ./docker-compose.yaml > .docker-compose.yaml; envsubst < ./filehub.conf > .filehub.conf;'
	podman-compose --in-pod=1 up	

run:
	podman run -d --name mi-test -p 8080:8080 mi-test:latest
	@trap 'echo "\nMakefile received Ctrl+C - stop logging..."; exit 0' INT; \
    	echo "logging container..."; \
    	podman logs --follow mi-test

clean:
	mvn clean

stop:
	podman stop mi-test || true

delete: 
	podman rm --force mi-test || true
	
fresh:	stop delete clean build run

test:
	curl -v http://localhost:8080/health

compose-up:
	podman-compose up

compose-down:
	podman-compose down

local:
	mvn clean package
	cp target/capp/artikelstammdaten_taxcodes_*.car mi-home/carbonapps
	podman-compose -f "docker-compose.local.yaml" up
