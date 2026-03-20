# Oracle Cloud VM

Services running on the Oracle Cloud free-tier VM (`mywikijs`). This VM is publicly accessible and hosts anything that needs to be reachable from the internet.

## Services

| Service | URL | Purpose |
|---|---|---|
| WikiJS | `wiki.ashishghimire.com` | Personal wiki / homelab docs |
| Nginx Proxy Manager | `<ip>:81` | Reverse proxy + SSL for all services |
| Umami | `umami.ashishghimire.com` | Blog analytics |

## Network

All services share `wiki-net`. NPM is the only container with ports 80/443 exposed — everything else is proxied through it.

Umami has an additional `umami-internal` network to isolate its Postgres from the rest.

## SSL

Cloudflare proxies all subdomains. Let's Encrypt HTTP challenge does not work behind Cloudflare proxy. Use a **Cloudflare Origin Certificate** instead — generate in Cloudflare dashboard, install as a custom certificate in NPM.

## Deploy order

```bash
# 1. Start wikijs first (creates wiki-net)
cd wikijs && docker compose up -d

# 2. Start NPM (joins existing wiki-net)
cd nginx && docker compose up -d

# 3. Start Umami
cd umami && docker compose up -d
```

## Migration notes

If migrating to the homelab:
- Umami needs public access for the tracking script — use Cloudflare Tunnel or deploy on k3s with an Ingress
- NPM can be replaced by Traefik (already running on k3s)
- WikiJS Postgres data is at `~/data/wiki/db/db-data` — dump and restore to new host
