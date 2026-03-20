# Umami Analytics

Self-hosted analytics for ashishghimire.com. Deployed on the Oracle Cloud VM (same host as WikiJS and Nginx Proxy Manager), not on the homelab.

## Why remote

The tracking script runs in visitors' browsers. If Umami is on the homelab, it needs to be publicly reachable — either via Cloudflare Tunnel or open ports. The Oracle VM is already public and already has NPM handling SSL and routing, so it was the obvious place.

## If you want to run this on the homelab instead

Umami needs to be publicly accessible for the tracking script to work. Two options:

- **Cloudflare Tunnel** — add Umami to the `cloudflare` network and configure a public hostname in the tunnel dashboard
- **Kubernetes** — deploy in the `personal` namespace and create an Ingress like any other service

The compose file works for either — just adjust the networks section.

## Deployment

On the Oracle VM, Umami joins the existing `wiki-net` Docker network so NPM can proxy it. Umami's Postgres is isolated in `umami-internal` — nothing else talks to it.

```bash
cp .env.example .env
# fill in .env
docker compose up -d
```

Then in NPM add a proxy host pointing `umami.ashishghimire.com` → `umami:3000`.

## Notes

- Default login is `admin` / `umami` — change immediately on first login
- Postgres data goes to the NFS path set in `UMAMI_DB_PATH`
- Generate secrets with `openssl rand -hex 32`
