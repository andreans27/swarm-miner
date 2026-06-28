# my_agent

Miner agent workspace (forked from current Swarm champion logic).

## Included in git

- `drone_agent.py` — ensemble router
- `agent_pt.py` — PyTorch detector path (mountain/village)
- `agent_onnx.py` — ONNX detector + XGBoost map classifier

## Not in git (download on VPS)

Model weights are large (~20 MB). After clone:

```bash
source miner_env/bin/activate
bash scripts/vps/download_champion.sh
```

Or full bootstrap:

```bash
bash scripts/vps/bootstrap.sh
```

## Package and benchmark

```bash
source miner_env/bin/activate
swarm model test --source my_agent/
swarm model package --source my_agent/
swarm benchmark --model Submission/submission.zip --seeds-per-group 1 --workers 4
```
