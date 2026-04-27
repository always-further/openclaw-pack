<p align="center">
  <img src="./nono-openclaw.png" alt="nono + OpenClaw" width="320" />
</p>

<h1 align="center">openclaw-pack</h1>

<p align="center">
  nono packs for <a href="https://openclaw.ai">OpenClaw</a> AI agents — sandboxing, multi-agent coordination, and capability-aware diagnostics.
</p>

---

## Packs

| Pack | Description |
|---|---|
| [`openclaw`](./openclaw/) | Sandbox profile, multi-agent coordination bus, and skill for all standard OpenClaw instance directories |

## Install

```bash
nono pull always-further/openclaw
```

Requires nono ≥ 0.42.0.

## Usage

**Single agent**

```bash
nono run --profile openclaw -- openclaw
```

**Multi-agent (parallel instances)**

```bash
nono run --profile openclaw -- openclaw
nono run --profile openclaw --home ~/.openclaw-agent1 -- openclaw
nono run --profile openclaw --home ~/.openclaw-agent2 -- openclaw
```

Each instance runs in its own isolated sandbox. Agents coordinate via a shared bus at `$TMPDIR/openclaw-$UID/` — readable and writable by all sandboxed instances on the same machine without breaking isolation.

## What this pack includes

| Artifact | Type | What it does |
|---|---|---|
| `policy.json` | profile | Sandbox policy covering all standard OpenClaw directories + coordination bus |
| `skills/openclaw-sandbox/SKILL.md` | instruction | Teaches the agent its sandbox constraints and how to diagnose permission failures |
| `bin/nono-hook.sh` | hook | Injects capability context into the agent when a sandbox denial occurs |

## Multi-agent coordination

When running multiple OpenClaw instances simultaneously, all agents share:

```
$TMPDIR/openclaw-$UID/
├── tasks/    ← shared task queue
├── locks/    ← file-based ownership (claim with noclobber)
└── state/    ← ephemeral per-agent status
```

Agents use this to avoid duplicate work, signal task ownership, and broadcast lightweight state — no network calls or shared database required.

## Publishing

Packs are published to the nono registry via GitHub Actions on tag push:

```bash
git tag openclaw-v0.2.0
git push origin openclaw-v0.2.0
```

The workflow at `.github/workflows/publish.yml` handles signing and publishing automatically.

---

<p align="center">
  Browse more packs at <a href="https://registry.nono.sh">registry.nono.sh</a>
</p>
