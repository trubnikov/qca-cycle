# Ocean × Hermes — a portable cognitive layer

**Persistent identity and growing memory for any LLM agent. The LLM is a swappable CPU; the personality is your data.**

This repository packages the cognitive core of [Ocean](https://github.com/trubnikov) — a personal
cognitive agent built by Dima Trubnikov in 2025, a year before agent memory became an industry
trend — as a single dependency-free skill for [Hermes Agent](https://github.com/NousResearch/hermes-agent).

## The idea

Popular agents conflate two things that must be separate:

| | Mainstream agents | This skill |
|---|---|---|
| Identity | dissolved in prompts & chat history, drifts silently | **immutable kernel** (axioms + guardrails), SHA-256 signed, injected into every cycle |
| Memory | append-only logs or RAG that fills with duplicates | **typed graph** (SUPPORTS/REFINES/CONTRADICTS) + **incorruptible novelty gate**: repeats are discarded by embedding geometry, not by an LLM grading itself |
| State | resets every session | **neurochemistry** (dopamine / pain / adrenaline / serotonin) with real half-lives, persists across sessions |
| Model | is the product | a **replaceable CPU**: mock / Ollama / Anthropic — swap it, the persona stays |

Architecture principle: *the LLM is a black-box CPU; every decision that matters —
what to recall, what to write, what to discard, when to speak — is made by auditable
deterministic code on top of it.*

## Quick start

```bash
# copy the skill into Hermes
cp -R skills/cognitive/qca-cycle ~/.hermes/skills/cognitive/

# seed a project decision, then think
export QCA_STORE=~/.hermes/qca/graph.json
python3 ~/.hermes/skills/cognitive/qca-cycle/scripts/qca_engine.py \
  seed "We decided NOT to cache decoded PCM audio — it eats memory" CORE
python3 ~/.hermes/skills/cognitive/qca-cycle/scripts/qca_engine.py \
  think "Should we cache decoded audio?"
# → "No — we already decided this: ..." (recalled, not guessed)

# give it a personality
cp skills/cognitive/qca-cycle/kernel.example.ses.json ~/.hermes/qca/kernel.ses.json

# wire the daemons (autonomous pulse + nightly memory consolidation)
hermes cron create "every 3h"  --name ocean-pulse --script ocean_pulse.sh --no-agent
hermes cron create "0 4 * * *" --name ocean-sleep --script ocean_sleep.sh --no-agent
```

Requires Python 3.10+. Optional: local Ollama with `bge-m3` for semantic embeddings
(graceful lexical fallback without it).

## Measured, not promised

All numbers from real runs (see `AB_RESULTS.md`):

- **A/B, 8 real-work tasks**: bare Hermes vs Hermes+QCA with seeded memory — QCA wins 6/8.
  Flagship case: the bare agent confidently recommended the *opposite* of a decision already
  made in the project; QCA recalled the decision (cosine 0.79, top-1).
- **Same model, same question** (Claude Fable 5 as CPU): bare — generic best practice;
  inside QCA — "No, we already decided this". Intelligence unchanged; relevance transformed.
- **Novelty gate**: exact repeat → cosine 0.987 → discarded, not written, dopamine drops.
- **Tamper test**: one character changed in a snapshot → SES verify fails loudly.

## What's in the box

```
skills/cognitive/qca-cycle/
├── SKILL.md                    # Hermes skill manifest (v0.13)
├── kernel.example.ses.json    # example personality kernel — copy & edit
└── scripts/
    ├── qca_engine.py          # the cycle: recall → contradiction → synthesis →
    │                          # critique → novelty gate → neurochemistry → write
    │                          # + daemons: pulse / sleep / soul; SES export
    └── ses_bridge.py          # SES integrity verify, lesson → skill export,
                               # importer for original Ocean SQLite memory
```

Pure stdlib, ~600 lines total. MIT license.

## Lineage

Ocean (2025) → OsGen v2 multi-entity field → this port (2026).
Built by a product designer, not a programmer — which is rather the point:
the thinking lives in the architecture, not in the code volume.
