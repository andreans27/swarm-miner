# VPS setup — Swarm miner dev

Clone this repo on Ubuntu 22.04+ (Vast.ai / RunPod / any VPS), then:

```bash
git clone git@github.com:andreans27/swarm-miner.git
cd swarm-miner
bash scripts/vps/bootstrap.sh
```

## What bootstrap does

1. System deps (Python 3.11, build tools, PM2)
2. `miner_env` virtualenv + `pip install -e .`
3. `swarm doctor`
4. Download champion weights into `my_agent/`
5. Smoke test package

## Daily workflow

```bash
source miner_env/bin/activate
swarm benchmark --model Submission/submission.zip --seeds-per-group 3 --workers 4
swarm report
```

## Remotes

| Remote | URL |
|--------|-----|
| origin | `andreans27/swarm-miner` — your fork |
| upstream | `swarm-subnet/swarm` — pull subnet updates |

Sync upstream:

```bash
git fetch upstream
git merge upstream/main
```

## Stop billing (cloud)

Destroy or stop the Vast/RunPod instance when idle. Running pod = charges continue.
