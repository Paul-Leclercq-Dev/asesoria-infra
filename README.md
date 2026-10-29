# asesoria-infra

Infrastructure as code for **Tramelya**, a multi-tenant SaaS CRM for Spanish advisory firms (*asesorías*).
Public on purpose: it is the DevOps part of the project. No secret lives here.

| Layer | Tool |
|---|---|
| Cloud (EU) | OVHcloud Public Cloud, Gravelines (`GRA11`) — OpenStack provider for compute/network, OVH provider for project users and S3 |
| DNS / edge | Cloudflare (proxied records, origin reachable only from Cloudflare IP ranges) |
| Remote state | OVHcloud Object Storage (S3), versioned, encrypted, native S3 lock, dedicated least-privilege user |
| Node bootstrap | cloud-init: non-root admin, SSH keys only, fail2ban, unattended upgrades, **k3s** |
| CI | `terraform fmt` / `validate`, tflint, Trivy (misconfig + secrets), actions pinned by SHA, Dependabot |

```
bootstrap/                  # run once: state bucket + scoped users (state migrates into its own bucket)
envs/demo/                  # 1-node k3s demo + Cloudflare zones (server can be switched off)
modules/server/             # instance + security group + cloud-init
modules/cloudflare-zone/    # zone, TLS settings, records, SPF/DMARC "no mail"
docs/                       # ADRs and runbooks
```

Design choices are in [`docs/adr/001-demo-platform.md`](docs/adr/001-demo-platform.md).
Step-by-step bootstrap (French): [`docs/bootstrap.fr.md`](docs/bootstrap.fr.md).

Security posture of the demo node: no inbound port except 22 (SSH keys only, password and root login disabled, fail2ban) and 443 (Cloudflare only);
the Kubernetes API (6443) is never exposed and is reached through an SSH tunnel.

GitOps (Argo CD), Helm charts, cert-manager and SOPS come next, in `asesoria-gitops`.
