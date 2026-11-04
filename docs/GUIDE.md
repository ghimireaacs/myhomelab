<sub><code>GUIDE · USE THIS LAB</code></sub>

# Running this yourself

Three ways in. Pick the smallest one that does what you want; each builds on the one before.

| | Path | You need | Time |
|---|---|---|---|
| **A** | [One service](#one-service) | Any Linux box with Docker | 10 minutes |
| **B** | [A stack](#a-stack) | One Docker host, a domain on Cloudflare | An afternoon |
| **C** | [Everything](#everything) | Proxmox, a NAS, a VLAN-capable router | A weekend |

Before any of them, read [`00` Conventions](#conventions): every stack in `docker/` follows them, and most problems come from skipping one.

---

<a id="conventions"></a>

## `00` · Conventions

| Convention | What it means for you |
|---|---|
| **`.env` per stack** | Every compose file reads its secrets, paths and addresses from `.env` beside it. `cp .env.example .env` and fill every value. Compose refuses to start when a required one is missing (`${VAR:?…}`). |
| **Placeholders only in git** | `.env.example` holds `change-me`, `example.com`, `192.0.2.x` (a documentation range). Nothing in it works as-is. |
| **State on local disk** | Paths like `*_DATA_PATH` must be on the host's own disk. Postgres and SQLite corrupt or refuse to start on NFS. |
| **Files on the NAS** | Libraries and documents (`MUSIC_LIBRARY_PATH`, `PAPERLESS_MEDIA_PATH`, `UPLOAD_LOCATION`) can be NFS. |
| **Pinned project `name:`** | Each compose file names its project, so `docker compose` from any checkout manages the same containers. |
| **Pinned images** | Versions are fixed on purpose. Upgrade one major at a time and read the release notes. |
| **Ports** | Every stack publishes a host port so it works without the proxy. `8080` is taken by cAdvisor on every VM here. |
| **Generate secrets** | `openssl rand -hex 32` for anything called `*_SECRET*`, `*_KEY`, `*JWT*`. |

```bash
# the shape of every stack
cd docker/<stack>
cp .env.example .env && $EDITOR .env
docker compose config -q          # validates: prints nothing when the .env is complete
docker compose up -d && docker compose logs -f
```

---

<a id="one-service"></a>

## A · One service

Any single folder in `docker/` runs alone on a host with Docker Engine and the compose plugin. No proxy, no SSO, no NAS needed: use local folders for every path and open `http://<host>:<port>`.

| Service | Folder | Port | Must set | Depends on |
|---|---|---|---|---|
| Paperless-ngx | `paperless` | 8000 | `PAPERLESS_SECRET_KEY`, admin user/password, the four paths | bundled Redis, Tika, Gotenberg |
| Actual Budget | `actual-budget` | 5006 | `ACTUAL_DATA_PATH` | the bank sync is optional (`--profile sync`) |
| Karakeep | `karakeep` | 3010 | both secrets, `KARAKEEP_DATA_PATH` | bundled Meilisearch + Chrome; Ollama optional |
| Vikunja | `vikunja` | 3456 | `VIKUNJA_JWT_SECRET`, data path | — |
| Wallos | `wallos` | 8092 | data path | — |
| Yamtrack | `yamtrack` | 8094 | `YAMTRACK_SECRET`, data path | bundled Redis |
| Glance | `glance` | 8090 | config/assets/data paths | a `glance.yml` in the config path |
| Radicale | `radicale` | 5232 | data path | — |
| Navidrome + yt-dlp | `media` | 4533, 8888 | config path, library paths | no indexers or download clients are configured |
| Immich | `immich` | 2283 | `UPLOAD_LOCATION`, `DB_DATA_LOCATION` (local!), DB password | bundled Postgres, Redis, ML |
| Nextcloud | `nextcloud` | `NEXTCLOUD_PORT` | admin, trusted domains, the data paths | bundled Postgres, Redis |
| Ollama + Open WebUI | `Ollama` | 11434, 3000 | the two data paths | an NVIDIA GPU + container toolkit for speed |
| Mattermost | `mattermost` | 8065 | Postgres user/password, `MM_SITEURL` | bundled Postgres |
| ntfy | `ntfy` | 2586 | cache/data paths | — |

Worked example, Paperless on a laptop:

```bash
git clone https://github.com/ghimireaacs/myhomelab && cd myhomelab/docker/paperless
cp .env.example .env
mkdir -p ~/paperless/{data,media,consume,export}
# in .env: PAPERLESS_DATA_PATH=~/paperless/data (absolute path), …, PAPERLESS_SECRET_KEY=$(openssl rand -hex 32)
docker compose up -d
# open http://localhost:8000 and drop a PDF in ~/paperless/consume
```

> **Note.** A few compose files set `PAPERLESS_URL=https://paperless.${BASE_DOMAIN}` or similar. Without a proxy, set `BASE_DOMAIN` to anything and reach the app by port; for Paperless also change `PAPERLESS_URL` and `PAPERLESS_CSRF_TRUSTED_ORIGINS` in its compose file to your `http://host:8000`, or logins fail with a CSRF error.

---

<a id="a-stack"></a>

## B · A stack

Stacks are groups that only make sense together. Bring them up in this order; each row assumes the ones above it.

| # | Stack | Folders | What it gives you |
|---|---|---|---|
| 1 | **Front door** | `traefik`, `authentik` | `https://<app>.your-domain` for everything, one wildcard certificate, SSO |
| 2 | **Eyes** | `monitoring`, `Dozzle`, `ntfy`, plus agents on each host (`defaultContainers` or the VM template) | Metrics, dashboards, live logs, phone alerts |
| 3 | **Everyday apps** | `glance`, `paperless`, `actual-budget`, `karakeep`, `vikunja`, `wallos`, `yamtrack`, `radicale` | The household's tools |
| 4 | **Media** | `media`, `immich` (and Jellyfin on a GPU host) | Music, TV, photos |
| 5 | **AI** | `Ollama`, `PaperlessAIs` | Local models; auto-tagging for Paperless and Karakeep |
| 6 | **Automation** | `n8n`, `cloudflareTunnel` | Workflows; the only thing exposed to the internet |

### 1 · Front door

You need a domain on Cloudflare and an API token with *Zone → DNS → Edit*.

1. In Cloudflare, add `A your-domain → <docker host LAN IP>` and `A *.your-domain → <same>`, **DNS only** (grey cloud). A private address in public DNS is fine: only your LAN can reach it.
2. `docker/traefik/.env`: `BASE_DOMAIN`, `ACME_EMAIL`, `CF_DNS_API_TOKEN`, `TRAEFIK_DATA_PATH`, and one `*_IP` per host your routes point at. Unused hosts can repeat the same address.
3. `docker compose up -d` (it creates the shared `proxy` network), then `docker logs traefik | grep -i certificate` until the wildcard is issued (a minute or two).
4. Edit `docker/traefik/dynamic/routes.yml`: delete the routers for apps you don't run. A route to a dead backend only returns 502; a missing env variable stops Traefik reading the file.
5. Authentik: fill its `.env`, `docker compose up -d`, open `https://auth.your-domain/if/flow/initial-setup/`.

```yaml docker/traefik/dynamic/routes.yml — adding an app
    myapp:                                  # under http.routers
      rule: "Host(`myapp.{{ $d }}`)"
      service: myapp
      middlewares: [lan-only]
    myapp:                                  # under http.services
      loadBalancer: {servers: [{url: "http://{{ $utility }}:1234"}]}
```

> **Field note.** *Symptom:* a new route returns 503. *Cause:* `dynamic/` lives on NFS here, and Traefik's file watcher gets no change events over NFS. *Fix:* `docker restart traefik` after every edit, or keep `dynamic/` on local disk.

### 2 · Eyes

1. On every Docker host: `cd docker/defaultContainers && docker compose up -d` (node-exporter 9100, cAdvisor 8080, Dozzle agent 7007). VMs built from the template already have them.
2. `docker/monitoring/.env`: the target lists are JSON arrays of `host:port`. Start with `./render.sh`, which writes `prometheus.yml` from the template and starts the stack.
3. `docker/Dozzle/.env`: `DOZZLE_REMOTE_AGENT=host1:7007,host2:7007`.
4. ntfy is deny-all: `docker exec ntfy ntfy user add --role=admin you`, then one token per publisher.

### 3 to 6 · Apps, media, AI, automation

Each is path A, plus a route in `routes.yml`. Points that bite:

- **Paperless** on an NFS inbox needs `PAPERLESS_CONSUMER_POLLING=1` (already set).
- **Immich** `DB_DATA_LOCATION` must be local disk. Back it up with `docker/immich/backup-postgres.sh`.
- **Karakeep** crawls pages with the bundled Chrome; `OLLAMA_BASE_URL` is optional.
- **n8n** is the one public app, through `cloudflareTunnel`. Nothing else needs a port forward.

---

<a id="everything"></a>

## C · Everything

The lab as it runs here: two Proxmox nodes, TrueNAS, OPNsense. Ansible does the host work from one control machine.

### 1 · Network

| VLAN | Purpose | Reaches |
|---|---|---|
| 10 Servers | Proxmox, VMs, NAS | the internet |
| 20 Personal | phones, laptops | Servers on 443 |
| 40 IoT | speakers, bulbs | the internet only (plus one Music Assistant exception) |
| 50 PC | the workstation | everything |
| 60 Security | Wazuh | agent ports from Servers |

Any router with VLANs works. The lab needs one thing from it: the server subnet must reach the NAS and the internet.

### 2 · Storage

One NFS export for files (here `ghostsilo`, mounted at `/home/ghost/ghostsilo` on every VM), one per app that needs its own (Nextcloud). Allow-list each export to the hosts that use it. Databases stay on the VMs.

### 3 · The VM template

```bash ansible/ (on your control machine)
cp inventory.ini inventory.local.ini && $EDITOR inventory.local.ini   # your Proxmox hosts and VMs
$EDITOR files/authorized_keys.ghost                                   # your public keys
# in proxmox-template.yml and proxmox-vm.yml: github_user, gateway, dns, build_ip, the NAS export
./run.sh proxmox-template.yml -i inventory.local.ini -e node=<proxmox host> -e template_id=9100
```

The template is Ubuntu 26.04 with Docker, log limits, key-only SSH, security updates, the NAS mount and the monitoring agents built in. It fetches your SSH keys from `github.com/<github_user>.keys`. It uses CPU type `x86-64-v2-AES` so it runs on older CPUs. Proxmox can't clone local-storage templates across nodes, so build it once per node.

### 4 · VMs

Declare them in `ansible/vars/vms.yml`, then one command each:

```yaml ansible/vars/vms.yml
vms:
  apps:
    vmid: 120
    node: pve1
    template: 9100
    ip: 10.0.10.120
    cores: 4
    memory: 6144
    disk: 64G
    storage: local-lvm
    tags: [docker]
```

```bash
./run.sh proxmox-vm.yml -i inventory.local.ini -e vm=apps
./run.sh baseline.yml   -i inventory.local.ini --limit apps --check --diff
./run.sh baseline.yml   -i inventory.local.ini --limit apps
```

The layout here: **utility** holds the front door, eyes and everyday apps; **ghostmedia** (on the second node) the media stack; **ghostgpu** everything that wants the GPU; **nextcloud** alone. Start with one VM for everything and split later. Moving a stack is: stop it, copy its data folder, start it on the new host, change one IP in Traefik's `.env`.

### 5 · Stacks

Follow path B in order on the VMs. The compose files run straight from the NAS checkout of this repo, so every VM sees the same `docker/` tree.

### 6 · Backups

```yaml ansible/host_vars/<vm>.yml
backup_paths:            # every *_DATA_PATH on this VM
  - /home/ghost/paperless/data
backup_pause_containers: # apps that write SQLite while running
  - paperless
```

`./run.sh backup.yml` dumps every Postgres/MariaDB container it finds and archives each path to `90_Backups/ansible/<vm>/` on the NAS, keeping 14 days. Schedule it with the systemd units in `ansible/systemd/`. **Restore one service once** before trusting it.

---

<a id="troubleshooting"></a>

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `required variable X is missing` | `.env` incomplete | `docker compose config -q` lists them |
| App 403 through Traefik, fine by port | Caller's address not in `lan-only` | Add the subnet to `middlewares.yml` (Docker's fallback pools are `192.168.0.0/16`) |
| Postgres "lock file is invalid" | Data folder on NFS | Move it to local disk |
| Every route 404 after editing `routes.yml` | A `{{ env "X" }}` with X unset, or a YAML error | `docker logs traefik` |
| VM from the template won't start on an old CPU | CPU type above what the host supports | Keep `x86-64-v2-AES` |
| Ansible ignores `ansible.cfg` | Folder is world-writable (NFS) | `run.sh` sets `ANSIBLE_CONFIG`; do the same |

Questions and fixes welcome as issues.
