#!/usr/bin/env python3
r"""One-way mirror: mydocs/wiki/*.md -> a SiYuan notebook.

git stays the source of truth. A changed file is deleted and recreated in
SiYuan, so edits made inside the mirror notebook are overwritten on the next
run; write trial notes in a different notebook.

    SIYUAN_URL=http://127.0.0.1:6806 SIYUAN_API_TOKEN=... \
    WIKI_DIR=/home/ghost/ghostsilo/99_System/Claude\ Codes/mydocs/wiki \
    python3 sync-wiki.py
"""
import hashlib
import json
import os
import re
import sys
import time
import urllib.request
from pathlib import Path

URL = os.environ.get("SIYUAN_URL", "http://127.0.0.1:6806").rstrip("/")
TOKEN = os.environ["SIYUAN_API_TOKEN"]
WIKI = Path(os.environ["WIKI_DIR"])
NOTEBOOK = os.environ.get("SIYUAN_NOTEBOOK", "Wiki (mirror)")
# Local disk, next to the workspace: which source hash each doc was built from.
STATE = Path(os.environ.get("SYNC_STATE", Path.home() / "siyuan" / "sync-state.json"))

FRONTMATTER = re.compile(r"\A---\n.*?\n---\n", re.S)


def api(endpoint, **payload):
    req = urllib.request.Request(
        f"{URL}/api/{endpoint}",
        data=json.dumps(payload).encode(),
        headers={"Authorization": f"Token {TOKEN}", "Content-Type": "application/json"},
    )
    # A just-created notebook answers "document metadata is not ready" for a few
    # seconds while it indexes; wait that out rather than failing the run.
    for attempt in range(10):
        with urllib.request.urlopen(req, timeout=30) as resp:
            body = json.load(resp)
        if body.get("code") == 0:
            return body.get("data")
        if "not ready" not in str(body.get("msg")):
            break
        time.sleep(2)
    raise RuntimeError(f"{endpoint}: {body.get('msg')}")


def notebook_id():
    for nb in api("notebook/lsNotebooks")["notebooks"]:
        if nb["name"] == NOTEBOOK:
            return nb["id"]
    return api("notebook/createNotebook", name=NOTEBOOK)["notebook"]["id"]


def ensure_parents(nb, hpath):
    # The API documents auto-created parents, but v3.8.9 rejects a nested path
    # whose parent is missing ("document metadata is not ready").
    parts = hpath.strip("/").split("/")[:-1]
    for i in range(1, len(parts) + 1):
        parent = "/" + "/".join(parts[:i])
        if not api("filetree/getIDsByHPath", notebook=nb, path=parent):
            api("filetree/createDocWithMd", notebook=nb, path=parent, markdown="")


def remove(nb, hpath):
    for doc_id in api("filetree/getIDsByHPath", notebook=nb, path=hpath) or []:
        api("filetree/removeDocByID", id=doc_id)


def main():
    if not WIKI.is_dir():
        sys.exit(f"WIKI_DIR not found: {WIKI} (NFS mount missing?)")

    nb = notebook_id()
    state = json.loads(STATE.read_text()) if STATE.exists() else {}
    seen, changed = set(), 0

    for md in sorted(WIKI.rglob("*.md")):
        rel = md.relative_to(WIKI).with_suffix("").as_posix()
        if any(part.startswith(".") for part in rel.split("/")):
            continue
        seen.add(rel)
        text = md.read_text(encoding="utf-8")
        digest = hashlib.sha256(text.encode()).hexdigest()
        if state.get(rel) == digest:
            continue
        hpath = f"/{rel}"
        remove(nb, hpath)
        ensure_parents(nb, hpath)
        api("filetree/createDocWithMd", notebook=nb, path=hpath,
            markdown=FRONTMATTER.sub("", text, count=1))
        state[rel] = digest
        changed += 1

    gone = set(state) - seen
    for rel in gone:
        remove(nb, f"/{rel}")
        del state[rel]

    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps(state, indent=1, sort_keys=True))
    print(f"synced: {changed} updated, {len(gone)} removed, {len(seen)} total")


if __name__ == "__main__":
    main()
