# Immich – Quick Guide

## Where Things Live

**Photos & Videos (do NOT delete)**
/home/ghost/ghostsilo/02_Media/Immich

**App Data (can be rebuilt)**
/home/ghost/ghostsilo/99_System/Docker-Data/immich

**Config Files**
/home/ghost/ghostsilo/99_System/Docker-Compose/immich

**Database Backups**
/home/ghost/ghostsilo/90_Backups/Immich/Database


## Start Immich

cd /home/ghost/ghostsilo/99_System/Docker-Compose/immich
docker compose up -d

Open in browser:
http://<VM-IP>:2283


## Update Immich

docker compose pull
docker compose up -d


## Logs

docker logs immich_server
docker logs immich_machine_learning


## Backup

Nightly at 3 AM → database dump saved to:

/home/ghost/ghostsilo/90_Backups/Immich/Database


## Restore Database

docker compose down

gunzip -c immich_db_YYYY-MM-DD.sql.gz \
 | docker exec -i immich_postgres psql -U postgres immich

docker compose up -d


## Rules

- Photos are normal files inside 02_Media/Immich
- Postgres must stay on local disk (not NFS)
- Config can be deleted and recreated
