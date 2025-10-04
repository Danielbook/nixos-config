#!/bin/bash

cd /srv/grafana-stack
docker compose pull
docker compose up -d --force-recreate
docker image prune -af
docker volume prune -f

cd /srv/traefik
docker compose pull
docker compose up -d --force-recreate
docker image prune -af
docker volume prune -f

cd /srv/portainer
docker compose pull
docker compose up -d --force-recreate
docker image prune -af
docker volume prune -f

cd /srv/mealie
docker compose pull
docker compose up -d --force-recreate
docker image prune -af
docker volume prune -f

cd /srv/homeassistant
docker compose pull
docker compose up -d --force-recreate
docker image prune -af
docker volume prune -f

cd /srv/homepage
docker compose pull
docker compose up -d --force-recreate
docker image prune -af
docker volume prune -f

cd /srv/esphome
docker compose pull
docker compose up -d --force-recreate
docker image prune -af
docker volume prune -f

cd /srv/unifi
docker compose pull
docker compose up -d --force-recreate
docker image prune -af
docker volume prune -f

