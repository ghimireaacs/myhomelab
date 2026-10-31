# SiYuan (3-day trial)

Trial on the **utility VM** (`10.10.10.114`), running alongside the existing wiki.
Nothing about the current wiki changes. `mydocs/wiki/` in git stays the source
of truth, and Quartz keeps publishing `wiki.example.xyz` as before.

SiYuan stores notes as its own `.sy` JSON, not `.md` files, so it can't edit
the wiki files in place. `sync-wiki.py` mirrors them one way into a notebook
called **Wiki (mirror)**:

```
mydocs/wiki/*.md  ──(every 15 min)──▶  SiYuan "Wiki (mirror)"
```

Anything edited inside **Wiki (mirror)** is overwritten the next time that page
changes in git. Write trial notes in a separate notebook.

## Deploy on utility

```bash
cd ~/ghostsilo/99_System/Claude\ Codes/myhomelab/docker/siyuan
mkdir -p ~/siyuan/workspace            # local disk, never NFS
cp -n .env.example .env                # set SIYUAN_WORKSPACE_PATH + auth code
docker compose up -d
```

Open `http://10.10.10.114:6806` and unlock with `SIYUAN_ACCESS_AUTH_CODE`.
Put the API token into `SIYUAN_API_TOKEN` in `.env`. It is shown in Settings,
and also stored in the workspace:

```bash
python3 -c 'import json;print(json.load(open("'$HOME'/siyuan/workspace/conf/conf.json"))["api"]["token"])'
```

## Mirror the wiki

Run it once by hand, then schedule it:

```bash
set -a; . ./.env; set +a
WIKI_DIR="$HOME/ghostsilo/99_System/Claude Codes/mydocs/wiki" python3 sync-wiki.py
# synced: 29 updated, 0 removed, 29 total
```

```cron
*/15 * * * * cd "$HOME/ghostsilo/99_System/Claude Codes/myhomelab/docker/siyuan" && set -a && . ./.env && set +a && WIKI_DIR="$HOME/ghostsilo/99_System/Claude Codes/mydocs/wiki" python3 sync-wiki.py >> "$HOME/siyuan/sync.log" 2>&1
```

Only changed files are rewritten. The script tracks them by hash in
`~/siyuan/sync-state.json`.

## What to judge in the trial

- Editing, block references and search compared with Obsidian.
- Whether wiki pages read well. Quartz `[[wiki-links]]` and relative images
  come across as plain text, and SiYuan adds its own frontmatter when exporting.
- Mobile/browser use. The Docker build is browser-only, with no desktop or mobile app connection.

## End of trial

**Keep it:** decide which side is the source of truth before writing anything
real. A two-way sync between SiYuan and git is not set up.

**Drop it:** remove the cron line, then:

```bash
docker compose down && rm -rf ~/siyuan
```

## Known issue

v3.8.9's `createDocWithMd` rejects a nested path whose parent page doesn't
exist yet, despite the docs saying parents are created automatically. It
answers "document metadata is not ready". The script creates parents first.
That same error also appears for a few seconds after a notebook is created,
and the script retries it.
