# Archive

Retired service definitions, kept for reference and data recovery. Nothing here is deployed: do not run `docker compose up` in these folders.

| Folder | Retired | Notes |
|---|---|---|
| `docker/postgres` | 2026-11-01 | `career-postgres`. Stopped and removed on utility and ghostgpu after crash-looping (two copies shared one NFS data dir). Data kept on the NAS at `99_System/Docker-Data/career-postgres/data` until the owner deletes it. |
| `docker/adminer` | 2026-11-01 | Owner: not used. Remove the container on utility with `docker rm -f adminer`. |
| `docker/nextdash` | 2026-11-01 | Owner chose Glance as the one dashboard ("NextDash too complex"). Never committed before archiving; dev-style build with port 8080, which clashes with cAdvisor. |
