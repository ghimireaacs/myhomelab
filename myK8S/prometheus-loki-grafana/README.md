# Prometheus · Loki · Grafana (PLG)

Minimal Kubernetes logging + metrics stack for homelab and small clusters.

This repository deploys:
- **Prometheus** → metrics collection (node-exporter, kube-state-metrics, cAdvisor)
- **Loki** → log storage
- **Promtail** → log shipping (file-based)
- **Grafana** → visualization (persistent, auto-provisioned datasources + dashboard)
- **syslog-ng** → syslog receiver / normalizer (OPNsense, routers, etc.)

Designed for **k3s / homelab / small clusters**, without Helm.

---

## Architecture overview

```
Devices (OPNsense, routers, servers)
↓  (UDP syslog, any format)
syslog-ng (K8s)
↓  (files on PVC)
Promtail (tail-only)
↓
Loki (persistent NFS PVC)
↓
Grafana
```

Metrics path:
```
node-exporter / cAdvisor / kube-state-metrics
↓
Prometheus (scrape)
↓
Grafana
```

### Why this design

- Promtail **does not parse raw syslog** — syslog-ng handles UDP/TCP, weird formats, and buffering
- Promtail only **tails files** (stable, low CPU)
- Loki is the **only stateful log component**

---

## Directory structure

```
prometheus-loki-grafana/
│
├── prometheus-config.yaml          # Scrape targets (envsubst)
├── prometheus-deployment.yaml
├── prometheus-service.yaml
│
├── loki-config.yaml
├── loki-deployment.yaml
├── loki-service.yaml
├── loki-pvc.yaml                   # NFS-backed PV + PVC (envsubst)
│
├── syslog-ng-config.yaml
├── syslog-ng-deployment.yaml
├── syslog-ng-service.yaml
├── syslog-ng-pvc.yaml              # NFS-backed PV + PVC
│
├── promtail-config.yaml
├── promtail-deployment.yaml
├── promtail-service.yaml
├── promtail-ingressroute-udp.yaml
│
├── node-exporter-daemonset.yaml
├── node-exporter-service.yaml
├── kube-state-metrics.yaml
│
├── grafana-deployment.yaml         # Authentik OAuth configured via env
├── grafana-service.yaml
├── grafana-ingress.yaml
├── grafana-secret.yaml.tmpl        # Secret template — apply via envsubst
├── grafana-pvc.yaml.tmpl           # NFS-backed PV + PVC (envsubst)
├── grafana-datasources.yaml        # Auto-provisions Prometheus + Loki datasources
├── grafana-dashboards.yaml         # Auto-provisions Homelab Overview dashboard
└── grafana-homelab-overview.json   # Source dashboard JSON
```

---

## Assumptions

- Kubernetes cluster is already running
- Namespace `infra` exists
- NFS server available for persistent storage
- `myK8S/.env` populated (copy from `myK8S/.env.example`)
- No Helm

---

## Secrets and env vars

All sensitive values use the envsubst pattern — `.tmpl` files contain `${VAR}` placeholders.

Required vars in `myK8S/.env`:

```bash
NFS_SERVER_IP=
NFS_LOKI_PATH=
NFS_SYSLOG_NG_PATH=
NFS_GRAFANA_PATH=

GRAFANA_ADMIN_PASSWORD=
GRAFANA_OAUTH_CLIENT_ID=
GRAFANA_OAUTH_CLIENT_SECRET=
AUTHENTIK_BASE_URL=
GRAFANA_ROOT_URL=

# Prometheus scrape targets (YAML list format)
NODE_EXPORTER_TARGETS=["x.x.x.x:9100","x.x.x.x:9100"]
CADVISOR_TARGETS=["x.x.x.x:8080","x.x.x.x:8080"]
K8S_NODE_EXPORTER_TARGETS=["x.x.x.x:9100","x.x.x.x:9100"]
```

Apply templates via the helper script:
```bash
myK8S/scripts/apply.sh myK8S/prometheus-loki-grafana/grafana-secret.yaml.tmpl
# or manually:
set -a; source myK8S/.env; set +a
envsubst < grafana-secret.yaml.tmpl | kubectl apply -f -
```

---

## Logging specifics

### syslog-ng
- Listens on **UDP 1514** via a LoadBalancer service
- Receives logs from OPNsense and other devices
- Writes to `/var/log/opnsense/opnsense.log` on a PVC

### Promtail
- Does **not** receive syslog directly
- Tails files from the syslog-ng PVC
- Pushes to Loki

### Loki
- Stores logs on NFS-backed PVC
- No local disk usage in other components

---

## OPNsense configuration

**System → Settings → Logging / Targets:**

| Field        | Value                                    |
|--------------|------------------------------------------|
| Transport    | UDP                                      |
| Port         | 1514                                     |
| Host         | LoadBalancer IP of syslog-ng service     |
| Applications | Firewall, System (or All)                |
| Enabled      | ✅                                       |

---

## How to apply

Recommended order:

```bash
# Loki
myK8S/scripts/apply.sh myK8S/prometheus-loki-grafana/loki-pvc.yaml
kubectl apply -f loki-config.yaml
kubectl apply -f loki-deployment.yaml
kubectl apply -f loki-service.yaml

# syslog-ng
kubectl apply -f syslog-ng-pvc.yaml
kubectl apply -f syslog-ng-config.yaml
kubectl apply -f syslog-ng-deployment.yaml
kubectl apply -f syslog-ng-service.yaml

# Promtail
kubectl apply -f promtail-config.yaml
kubectl apply -f promtail-deployment.yaml
kubectl apply -f promtail-service.yaml

# Prometheus
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus-deployment.yaml
kubectl apply -f prometheus-service.yaml
kubectl apply -f node-exporter-daemonset.yaml
kubectl apply -f node-exporter-service.yaml
kubectl apply -f kube-state-metrics.yaml

# Grafana
myK8S/scripts/apply.sh myK8S/prometheus-loki-grafana/grafana-secret.yaml.tmpl
myK8S/scripts/apply.sh myK8S/prometheus-loki-grafana/grafana-pvc.yaml.tmpl
kubectl apply -f grafana-datasources.yaml
kubectl apply -f grafana-dashboards.yaml
kubectl apply -f grafana-deployment.yaml
kubectl apply -f grafana-service.yaml
kubectl apply -f grafana-ingress.yaml
```

---

## Grafana

### Persistent storage
Grafana data (users, dashboards saved in UI, preferences) is stored on an NFS-backed PVC at `/var/lib/grafana`. Nothing is lost on pod restarts.

### Auto-provisioned datasources
`grafana-datasources.yaml` provisions Prometheus and Loki automatically on startup — no manual setup needed.

| Name       | Type       | UID          | URL                        |
|------------|------------|--------------|----------------------------|
| Prometheus | prometheus | `prometheus` | `http://prometheus:9090`   |
| Loki       | loki       | `loki`       | `http://loki:3100`         |

### Auto-provisioned dashboard
`grafana-dashboards.yaml` provisions the **Homelab Overview** dashboard (CPU, RAM, network per host, K8s pods by namespace). It loads automatically and is marked read-only in the UI. Edit `grafana-homelab-overview.json` and re-apply the ConfigMap to update it.

### Authentik OAuth
OAuth is configured entirely via environment variables in `grafana-deployment.yaml`, sourced from the `grafana-admin` secret. Role mapping:
- Members of `grafana-admins` group → **Admin**
- Members of `authentik Admins` group (Authentik superusers) → **Admin**
- All other authenticated users → **Viewer**

---

## Notes

- Loki is the only persistent log store
- syslog-ng persistence is recommended for debugging
- Promtail is stateless
- All secrets use the `.tmpl` + envsubst pattern — never committed
- Dashboards and datasources are provisioned via ConfigMap — no manual import needed

---

## What this is NOT

- Not a full SIEM
- Not IDS/IPS
- Not a Wazuh / ELK replacement

This is a **clean logging + metrics foundation** you can grow later.

---

## Future extensions

- Loki parsing pipelines (filterlog fields)
- Firewall dashboards (blocked IPs, ports, scans)
- CrowdSec integration
- Alerting rules (Grafana or Loki ruler)
- GeoIP enrichment
