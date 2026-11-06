# AGENTS.md

Guidance for agents (and humans) working in this repository.

## What this project is

A minimal Docker image for the [CrowdSec Firewall Bouncer](https://docs.crowdsec.net/docs/bouncers/firewall-bouncer/)
with nftables support, published to GHCR.

- **Single `Dockerfile`** (Debian bookworm-slim). The bouncer version appears **three times** — the
  download URL, `mv /tmp/crowdsec-firewall-bouncer-v<ver>/…` and
  `rm -rf …/crowdsec-firewall-bouncer-v<ver>` — and all three must move together: the regex manager
  in `renovate.json` rewrites each of them. `build.yml` extracts the version from the download URL
  with `grep -oP 'releases/download/v\K[0-9.]+' Dockerfile`. A bump that only touches the URL builds
  a broken image (the `mv` fails on the new tarball directory).
- `config/crowdsec-firewall-bouncer.yaml` is the default config baked into the image
  (placeholder key); deployments always mount their own file over it.
- This fork **intentionally diverged** from upstream: single nftables image, no iptables variant,
  no `entrypoint.sh`/compose/e2e PowerShell tests (`0736bca`). Don't "restore" upstream structure
  without an explicit decision.

## Remotes & upstream

- `origin` → `mathieuruellan/crowdsec-firewall-bouncer-docker` (this fork, the canonical copy).
- `forkorigin` → `david-garcia-garcia/crowdsec-firewall-bouncer-docker` (original project).
- Keep them in sync *manually*; the `upstream-sync-check` workflow only **alerts** (see below).
- Manual check: `git fetch forkorigin && git rev-list --left-right --count master...forkorigin/master`
  (upstream currently fully contained: ahead-only).

## CI (`.github/workflows/`)

- **`build.yml`** — builds and pushes to GHCR on push to `master`, tag `v*`, `create` (tags only),
  `workflow_dispatch`.
  - Tags emitted: `vX.Y.Z-bouncer-<ver>` and `X.Y.Z-bouncer-<ver>` (tag events),
    `latest-bouncer-<ver>` (default branch only). There is **no** bare `latest` and no short
    semver tags — the `*-debian-12-*` tags in the registry are historical leftovers.
  - A tag push fires **two** runs (`push:tags` + `create`); they build identical source — wait for
    both before recording a release digest.
- **`upstream-sync-check.yml`** — daily (06:17 UTC) + dispatch. Fetches `forkorigin` over public
  HTTPS (no token), fails the run and opens/updates a single sticky issue when upstream has commits
  not in `master`. Informational only: **never** merge, rebase, build, or tag from it. The
  `simulate_upstream_move` input exercises the alert path (compares against
  `forkorigin/initial-fixes`, which is fetched only while simulating).
- **`renovate.yml`** — weekly (Mon 05:00) + dispatch; `renovate.json` restricts autodiscover to this
  repo. The `log_level` dispatch input (`info`/`debug`/`trace`) is forwarded to the container's
  `LOG_LEVEL` — use `gh workflow run renovate.yml -f log_level=debug` when an expected update never
  appears.
  - `renovate.json` sets `ignoreUnstable: true`, and the `github-tags` datasource takes `isStable`
    from the matching **GitHub release**. While upstream keeps a release flagged *pre-release*,
    Renovate silently ignores it: no branch, no PR, no dashboard arrow and **no warning** (this is
    why `v0.0.38` was skipped for five weeks, until its release was un-flagged on 2026-11-03).
    Check `gh api repos/<owner>/<repo>/releases/tags/<tag> --jq .prerelease` before assuming a
    config problem.
  - Do **not** pass `configurationFile:` to the action: it mounts the repo `renovate.json` as
    `RENOVATE_CONFIG_FILE` *and* Renovate reads the same file from the repo, so `customManagers` is
    merged twice (duplicate deps, `Cannot find replaceString … Was it already updated?`).

## Hard rules (live deployments depend on these)

1. **Never delete, move or re-tag a published image tag.** Tags are immutable release artifacts;
   hosts pin them (rollback = re-pin an older tag).
2. Don't add push/merge/build steps to `upstream-sync-check.yml`.
3. Never commit secrets — no API keys in `config/` (placeholder values only).

## Where the image runs

Only one host consumes it: **biniou.bastion**.

- Compose lives in a **different repo**: Forgejo `bastion.git` (local mirror
  `~/projects/komodo/bastion`, path `zz-crowdsec/docker-compose.yml`), image currently pinned to
  `ghcr.io/mathieuruellan/crowdsec-firewall-bouncer-docker:v1.1.0-bouncer-0.0.36`.
- Update flow: commit + push there → **as root** on the host
  (`git -C /etc/docker-compose pull --ff-only && docker compose -f /etc/docker-compose/zz-crowdsec/docker-compose.yml up -d firewall-bouncer`).
  `mathieu` has no SSH key on that host, and `zz-crowdsec/` + `.forgejo/workflows/` are root-owned,
  so non-root pulls/merges fail.
- `zz-crowdsec/config/bouncer.yaml` carries the **live `api_key`** as an uncommitted host-local
  edit; before any pull verify incoming commits don't touch it.
- Other fleet hosts run CrowdSec *agents* (`crowdsecurity/crowdsec`) only — not this image.

## Verify a deployed bouncer

```bash
docker logs crowdsec-firewall-bouncer                            # "nftables initiated", "Using API key auth", "N decisions added"
docker exec crowdsec-firewall-bouncer nft list table ip crowdsec # + "ip6 crowdsec6"
```

Full `nft list ruleset` **segfaults inside the container** (rc=139) — always use the targeted
table listing.

## Local build

```bash
docker build -t crowdsec-firewall-bouncer .
```
