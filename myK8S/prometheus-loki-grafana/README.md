# Prometheus · Loki · Grafana (PLG)

Minimal Kubernetes logging + metrics stack for homelab and small clusters.

This repository deploys:
- **Prometheus** → metrics collection
- **Loki** → log storage
- **Promtail** → log shipping (file-based)
- **Grafana** → visualization
- **syslog-ng** → syslog receiver / normalizer (OPNsense, routers, etc.)

Designed for **k3s / homelab / small clusters**, without Helm.

---

## Architecture overview

This setup intentionally separates concerns:

```

Devices (OPNsense, routers, servers)
↓  (UDP syslog, any format)
syslog-ng (K8s)
↓  (files on PVC)
Promtail (tail-only)
↓
Loki (persistent)
↓
Grafana

```

### Why this design

- Promtail **does not parse raw syslog**
- syslog-ng handles:
  - UDP/TCP syslog
  - weird formats
  - buffering
- Promtail only **tails files** (stable, low CPU)
- Loki is the **only stateful log component**

This avoids common syslog parsing issues and scales cleanly.

---

## Directory structure

```

prometheus-loki-grafana/
├── prometheus-config.yaml
├── prometheus-deployment.yaml
├── prometheus-service.yaml
│
├── loki-config.yaml
├── loki-deployment.yaml
├── loki-service.yaml
├── loki-pvc.yaml
│
├── syslog-ng-config.yaml
├── syslog-ng-deployment.yaml
├── syslog-ng-service.yaml
├── syslog-ng-pv.yaml
├── syslog-ng-pvc.yaml
│
├── promtail-config.yaml
├── promtail-deployment.yaml
├── promtail-service.yaml
│
├── grafana-deployment.yaml
├── grafana-service.yaml
├── grafana-ingress.yaml
├── grafana-secret.yaml
├── grafana-secret.yaml.example

```

Each component is split into:
- config
- deployment
- service  
Stateful components include PV/PVC where required.

---

## Assumptions

- Kubernetes cluster is already running
- Namespace `infra` exists
- NFS (or equivalent) is available for persistent storage
- No Helm is used
- OPNsense (or other devices) can send syslog over UDP

---

## Logging specifics (important)

### syslog-ng
- Listens on **UDP 1514** via a LoadBalancer service
- Receives logs from OPNsense and other devices
- Writes logs to:
```

/var/log/opnsense/opnsense.log

```
backed by a PVC

### Promtail
- **Does not receive syslog**
- Tails files from the same PVC:
```

/var/log/opnsense/*.log

````
- Pushes logs to Loki

### Loki
- Stores logs on persistent NFS-backed PVC
- No local disk usage in other components

---

## OPNsense configuration

Configure **System → Settings → Logging / Targets**:

| Field        | Value                                   |
|--------------|------------------------------------------|
| Transport    | UDP                                      |
| Port         | 1514                                     |
| Host         | `syslog-ng.<namespace>.svc.cluster.local` **or** LoadBalancer IP |
| Applications | Firewall, System (or All)                |
| Enabled      | ✅                                        |

No syslog-ng runs on OPNsense itself — it is fully offloaded.

---

## How to use

### 1. Review and adjust values

#### Prometheus targets
Edit `prometheus-config.yaml`:
```yaml
- targets:
  - 10.10.10.11:9100
  - 10.10.10.12:9100
````

Replace with your node-exporter endpoints.

---

#### Loki storage (important)

Edit `loki-pvc.yaml`:

```yaml
nfs:
  server: 10.10.10.200
  path: /mnt/ghostdata/ghostsilo/99_System/K8S-Data/loki
```

---

#### syslog-ng storage

Edit `syslog-ng-pv.yaml` / `syslog-ng-pvc.yaml` to point to:

```
/mnt/ghostdata/ghostsilo/99_System/K8S-Data/syslog-ng
```

(or your preferred path)

---

#### Grafana access

* Copy `grafana-secret.yaml.example` → `grafana-secret.yaml`
* Set a secure admin password
* Adjust `grafana-ingress.yaml` host if using ingress

---

### 2. Apply manifests

Recommended order:

```bash
# Loki
kubectl apply -f loki-pvc.yaml
kubectl apply -f loki-config.yaml
kubectl apply -f loki-deployment.yaml
kubectl apply -f loki-service.yaml

# syslog-ng
kubectl apply -f syslog-ng-pv.yaml
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

# Grafana
kubectl apply -f grafana-secret.yaml
kubectl apply -f grafana-deployment.yaml
kubectl apply -f grafana-service.yaml
kubectl apply -f grafana-ingress.yaml
```

---

## Notes

* **Loki is the only persistent log store**
* syslog-ng persistence is optional but recommended for debugging
* Promtail is intentionally stateless
* Dashboards are imported manually by ID
* Alerting can be added later (Grafana or Loki ruler)

---

## What this repo is NOT

* ❌ Not a full SIEM
* ❌ Not IDS/IPS
* ❌ Not Wazuh / ELK replacement

This is a **clean logging foundation** you can grow later.

---

## Future extensions (optional)

* Loki parsing pipelines (filterlog fields)
* Firewall dashboards (blocked IPs, ports, scans)
* CrowdSec integration
* Alerting rules
* GeoIP enrichment

None of these require redesigning this stack.

---

## License

Use, modify, break, rebuild.


