# Syncthing

Runs on the utility VM (`docker/syncthing/`). Provides file sync across devices — phones, laptops, workstations.

## Deploy

```bash
cp .env.example .env
# fill in real paths
docker compose up -d
```

Web UI: `http://10.10.10.114:8384` — set a password immediately (Actions → Settings → GUI).

---

## Device addressing rules

Syncthing devices need to know how to reach each other. The address field on a device entry means **"how to reach that device"** — not "how to reach the server."

**Rule: stationary hosts get pinned addresses. Mobile devices are always `dynamic`.**

| Device entry (as seen from...) | Address |
|---|---|
| Server entry on any client | `tcp://10.10.10.114:22000` |
| Windows entry on Pixel | `tcp://10.10.50.100:22000` |
| Phone entry on server | `dynamic` |
| Phone entry on PC/laptop | `dynamic` |
| PC/laptop entry on server | `dynamic` (or pin if static IP) |

Phones never get pinned — their IP changes across WiFi, mobile data, and networks. Let phones always be the ones that dial out to known hosts.

Cross-VLAN devices that can't use local discovery must have their addresses pinned. Without a pinned address, Syncthing falls back to global discovery — which is off in this setup, so the connection never happens.

## Topology

3-way sync: phone ↔ server ↔ PC, plus phone ↔ PC directly over LAN.

```
Pixel (VLAN 20)
    │  tcp://10.10.10.114:22000
    ▼
Utility VM / server (VLAN 10)  ◄──── dynamic ────  Windows PC (VLAN 50)
    ▲                                                      ▲
    └──────────────── dynamic (port 22000) ────────────────┘
```

Phone → PC direct sync requires OPNsense firewall rule on PERSONAL interface:
`Pass TCP/UDP PERSONAL net → PC net port 22000` — placed above any PERSONAL → PC block rule.

---

## Pairing devices

Don't manually type device IDs. Let Syncthing do it:

1. Open Syncthing on both devices
2. On the device trying to connect, make sure it has the server's address (`tcp://10.10.10.114:22000`) if connecting to the server
3. A banner appears on the receiving end: **"Device X wants to connect — Add device?"**
4. Click **Add Device**, give it a name, save
5. The other side gets the same prompt — approve it there too
6. Both sides approved = connected

---

## Cross-VLAN notes

Local discovery (UDP multicast) does not cross VLAN boundaries. Devices on different VLANs will not auto-discover each other. This is expected.

**Fix:** pin the server address on every client (see table above). Clients connect directly by IP — no discovery needed.

Global discovery and relay should be **disabled** (Actions → Settings → Connections) to keep all traffic on the LAN.
