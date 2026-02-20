# 📺 GhostMedia IPTV Stack

## 📂 Submodules
This directory uses Git Submodules.

**To update code:**
```bash
git submodule update --remote --merge
````

**To initial install (if cloning fresh):**

```bash
git submodule update --init --recursive
```

## 🚀 Deployment

1.  Edit `docker-compose.yml` and set `API_URL` to your Server LAN IP.
2.  Run:
    ```bash
    docker compose up -d --build
    ```

