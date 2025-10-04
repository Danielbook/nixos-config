#!/bin/bash

cd /srv/homeassistant-stack
docker compose pull
docker compose up -d --force-recreate
docker image prune -af
docker volume prune -f

cd /srv/traefik
docker compose pull
docker compose up -d --force-recreate
docker image prune -af
docker volume prune -f

cd /srv/octoprint
docker compose pull
docker compose up -d --force-recreate
docker image prune -af
docker volume prune -f

cd /srv/mealie
docker compose pull
docker compose up -d --force-recreate
docker image prune -af
docker volume prune -f
