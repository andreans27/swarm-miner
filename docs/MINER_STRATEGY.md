# Swarm Miner Strategy Plan

Long-term robust path for Subnet 124 (Swarm). Goal: competitive, maintainable miner that can improve across epoch rotations—not a one-off ensemble hack.

**Related docs:** [miner.md](miner.md) · [king_of_the_hill.md](king_of_the_hill.md) · [VPS.md](VPS.md)

---

## 1. Strategic thesis

| Principle | Detail |
|-----------|--------|
| **Paradigm** | Modular stack (perception → planner → geometry → control), not pure end-to-end RL |
| **Training** | Offline ML + optional RL residual; inference is frozen policy + FSM |
| **Competition model** | King of the Hill — last 10 champions share emissions; beat champion by dynamic floor |
| **Submission model** | One hotkey = one model, lifetime; commit only when metrics pass |
| **Iteration** | Retrain perception when seeds rotate (weekly); FSM/heuristics evolve in code |

Champion (UID 238, ~0.812) proves modular engineering wins. Our edge: **clean single codebase**, **village reliability**, **time on strong maps**—not merging two full agents like the current champion.

---

## 2. Target architecture

```
depth + state
    │
    ▼
┌─────────────────────────────────────┐
│ Layer 1 — Perception ML             │
│  • Goal detector (pad position)     │
│  • Map classifier (6 env types)     │
│  Retrainable each epoch             │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ Layer 2 — Planner FSM               │
│  takeoff → search → nav → land      │
│  Stable safety shell; map-adaptive  │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ Layer 3 — Geometry                  │
│  Ray-cast obstacle avoidance        │
│  No training required               │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ Layer 4 — RL residual (Phase 3+)    │
│  Small net: Δaction on top of base  │
│  Village, landing, time optimization│
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ Layer 5 — Eval gate                 │
│  Local benchmark before any commit  │
└─────────────────────────────────────┘
    │
    ▼
 action [dir_x, dir_y, dir_z, speed, yaw]
```

### Explicit non-goals (for now)

- Pure end-to-end RL from scratch
- Running two full agents every tick (champion ensemble hack)
- Committing before full local benchmark passes gates below

---

## 3. Phased roadmap

### Phase 0 — Infrastructure (current)

| Task | Done when |
|------|-----------|
| Repo fork + VPS bootstrap | `bash scripts/vps/bootstrap.sh` passes |
| Champion baseline downloaded | Weights in `my_agent/`, package succeeds |
| Per-map baseline benchmark | Report saved; village weakness confirmed |

**Cloud:** Vast.ai RTX 3090 (~$0.19/hr) for exploration; top up before serious training.

---

### Phase 1 — Clean modular (Weeks 1–2)

**Objective:** Single agent codebase; remove dual-agent router debt.

| Task | Output |
|------|--------|
| Merge `agent_pt` + `agent_onnx` into one controller | One `DroneFlightController`, shared state |
| Map label → **parameter profiles**, not full agent swap | `MAP_PROFILES[village]`, etc. |
| Keep: FSM, ray-cast, goal detector, nav ONNX | Parity with champion logic |
| Drop: run-both-agents-every-tick | Lower latency, easier debug |

**Gate to Phase 2:**

| Metric | Target |
|--------|--------|
| Overall avg (≥3 seeds/group, all 6 maps) | ≥ 0.80 |
| No map regression vs champion baseline | > −0.05 vs champion per map |
| `swarm model verify` | Pass |
| Package size | ≤ 50 MiB |

---

### Phase 2 — Village & weak-map fix (Week 3)

**Objective:** Fix lowest ceiling; champion village ~0.548 drags average.

| Experiment | Hypothesis |
|------------|------------|
| Route village to ONNX detector path | PT detector weak on village |
| Village-specific search params | Shorter arms, faster rotation exit |
| Retrain / fine-tune goal detector (village-heavy) | Perception bottleneck |
| Static landing lock for village if applicable | Reduce landing failures |

**Gate to Phase 3:**

| Metric | Target |
|--------|--------|
| **Village** avg | ≥ **0.70** |
| Mountain | ≥ 0.78 |
| City, open, warehouse | ≥ 0.85 each |
| Forest | ≥ 0.82 |
| **Overall avg** | ≥ **0.82** |
| Beat champion + floor locally | ≥ 0.812 + 0.005 = **0.817** (adjust if champion moves) |

---

### Phase 3 — Imitation + RL residual (Weeks 4–6)

**Objective:** Beat modular ceiling on edge cases; optimize time on strong maps.

| Step | Method |
|------|--------|
| 1. Rollout collection | Record (obs, action, mode, map) from fork on diverse seeds |
| 2. Behavior cloning | Train small net to mimic nav-phase actions |
| 3. RL residual | `action = base + α·residual(obs)`; PPO/SAC; village oversampled |
| 4. Safety shell | Keep FSM + ray-cast for landing and collision guard |

**Gate to commit candidate:**

| Metric | Target |
|--------|--------|
| Overall avg (full local benchmark, 800+ seeds equivalent) | ≥ **0.83** |
| Beat champion + dynamic floor | ≥ champion + 0.005–0.015 |
| Village | ≥ 0.75 |
| Screening simulation (200 seeds) | Pass floor on stitched score |
| Consistency | 2 consecutive benchmark runs within ±0.01 overall |

---

### Phase 4 — Epoch maintenance (ongoing)

Seeds rotate **every 7 days** (Monday 16:00 UTC).

| Weekly cycle | Action |
|--------------|--------|
| Mon | Pull new seeds from [swarm124.com](https://swarm124.com) |
| Mon–Tue | Retrain goal detector if drift detected |
| Wed | RL residual fine-tune (village-heavy subset) |
| Thu | Full local benchmark |
| Fri | Analyze per-map report; tune FSM only if needed |
| Sat | Commit **only if** all commit gates pass |

---

## 4. Success metrics

### 4.1 Scoring reference (validator)

```
score = 0.45 × success + 0.45 × time + 0.10 × safety
```

| Term | Weight | Fail mode |
|------|--------|-----------|
| Success | 0.45 | No valid landing → 0 success term |
| Time | 0.45 | Slow search/nav → linear decay |
| Safety | 0.10 | Low clearance; collision → **0.01** total (grace) |

**Implication:** Success first (especially village). Time optimization only after success stable per map.

---

### 4.2 Benchmark tiers (local)

Use before every major decision:

| Tier | Command | Purpose | Min frequency |
|------|---------|---------|---------------|
| **Smoke** | `--seeds-per-group 1` | Fast regression after code change | Every edit session |
| **Screening** | 200 seeds equivalent / per-map subset | Mimic validator screening | Before Phase gate |
| **Full** | 800+ seeds / `--seeds-per-group 10+` | Pre-commit validation | Before chain commit |
| **Champion compare** | Same seeds as last champion run | Relative delta | Weekly |

---

### 4.3 Per-map minimums (pre-commit)

Do **not** commit until **all** rows pass:

| Map | Min avg score | Champion ref (UID 238) | Priority |
|-----|---------------|------------------------|----------|
| City | 0.85 | 0.889 | Medium |
| Open | 0.85 | 0.871 | Medium |
| Warehouse | 0.88 | 0.909 | Low (already strong) |
| Forest | 0.82 | 0.846 | Medium |
| Mountain | 0.78 | 0.803 | Medium |
| **Village** | **0.70** | **0.548** | **Critical** |

---

### 4.4 Global commit gates (one-shot hotkey)

All must be true:

| # | Gate | Threshold |
|---|------|-----------|
| 1 | Overall benchmark avg | ≥ champion + **dynamic floor** (0.005–0.015) |
| 2 | Overall benchmark avg | ≥ **0.817** (adjust to live champion) |
| 3 | Per-map minimums | See §4.3 |
| 4 | `swarm model verify` | Pass |
| 5 | README + submission | Template README exact hash; zip ≤ 50 MiB |
| 6 | Docker whitelist | All deps approved |
| 7 | Consistency | 2 full runs within ±0.01 overall |
| 8 | Screening proxy | Stitched 200-seed score ≥ floor |

**Dynamic floor (dethrone):**

| Champion score | Required improvement |
|----------------|----------------------|
| ≤ 0.35 | +0.015 |
| → 1.00 | decays to +0.005 |

---

### 4.5 King of the Hill (emission) targets

Not required for first commit, but long-term success:

| Milestone | Meaning |
|-----------|---------|
| Crowned king | Pass screening + full benchmark + beat floor |
| Stay in top-10 window | Score remains competitive across re-eval |
| Improve frontier | Log-headroom gain at crown time |

Track via API: `GET https://api.swarm124.com/kings/active`

---

### 4.6 Infrastructure & cost metrics

| Metric | Target |
|--------|--------|
| VPS bootstrap time | < 30 min clone → first smoke benchmark |
| Cloud GPU spend (explore) | ≤ $25/mo (3090 tier) |
| Cloud GPU spend (competitive) | $40–70/mo (4090/5090 tier) |
| Benchmark wall time (smoke) | < 30 min on 16 vCPU |
| Benchmark wall time (full) | < 12 hr overnight acceptable |

---

## 5. Decision tree

```
Local smoke pass?
├── No  → fix code, do not benchmark further
└── Yes
    └── Phase 1 gate pass (≥0.80)?
        ├── No  → stay Phase 1 (merge agents, debug)
        └── Yes
            └── Phase 2 gate pass (village ≥0.70, overall ≥0.82)?
                ├── No  → village experiments only
                └── Yes
                    └── Phase 3 gate pass (≥0.83, beat floor)?
                        ├── No  → IL + RL residual
                        └── Yes → commit candidate
                            └── 2 consistent full runs?
                                ├── No  → tune, do not commit
                                └── Yes → GitHub + chain commit (one shot)
```

---

## 6. Risk register

| Risk | Mitigation |
|------|------------|
| One-shot hotkey wasted | Never commit until §4.4 all pass |
| Village remains weak | Phase 2 dedicated; oversample in Phase 3 |
| Epoch seed drift | Weekly retrain perception; keep eval loop |
| Cloud budget burn | 3090 explore; stop instance when idle; CPU pod for benchmark |
| Ensemble debt | Phase 1 explicitly removes dual-agent pattern |
| Front-running | Private repo → chain commit → public repo |
| Duplicate model hash | Ensure meaningful diff before commit |

---

## 7. Current baseline (reference)

| Field | Value | Date |
|-------|-------|------|
| Champion UID | 238 | 2026-06-28 |
| Champion score | 0.8117 | |
| Champion repo | https://github.com/leec-72991-a10y/2 | |
| Our fork | `my_agent/` from champion code | |
| Weak map | Village 0.548 | |

Update this table when champion changes on [leaderboard](https://swarm124.com/benchmark).

---

## 8. Immediate next actions

1. Push `swarm-miner` repo; clone on Vast RTX 3090
2. Run `scripts/vps/bootstrap.sh`
3. Smoke benchmark champion package → save report as **Phase 0 baseline**
4. Start Phase 1: merge agents into single controller
5. Log all benchmark results in `bench_logs/` (gitignored) for comparison

---

## 9. Document history

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2026-06-28 | Initial strategy from architecture brainstorm |
