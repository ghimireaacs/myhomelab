# SSH Keys

Place your SSH public key here as `bootstrap.pub`.
This key is injected into VMs via cloud-init at provisioning time.

Generate a dedicated bootstrap keypair:

```bash
ssh-keygen -t ed25519 -C "terraform-bootstrap" -f ./bootstrap
# bootstrap     ← private key (never commit)
# bootstrap.pub ← public key (safe to commit)
```

The private key (`bootstrap`) is gitignored.
After provisioning, add your personal SSH key to the VM and remove the bootstrap key.
