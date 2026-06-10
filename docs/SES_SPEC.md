# SES — Semantic Energy System, snapshot format (v5.1, as implemented)

SES is a serialization format for an agent's **identity and memory as verifiable data**.
This document specifies exactly what `qca_engine.py` reads and writes, so that any
implementation in any language can produce compatible snapshots.

There are two snapshot types with different mutability rules:

| Snapshot | File | Mutability | Role |
|---|---|---|---|
| **Kernel** | `kernel.ses.json` | immutable | constitution: who the agent is |
| **State** | `snapshot.ses.json` | grows | biography: what the agent has lived |

The separation is the core design decision: identity must not drift as a side effect
of experience. The kernel changes only by a deliberate new snapshot — which produces
a new hash, making personality evolution *versioned* like code.

---

## 1. Kernel snapshot (`FRACTAL_KERNEL`)

```json
{
  "initiator": "∮",
  "schema_version": "SES v5.1",
  "entity_id": "MyAgent",
  "snapshot_type": "FRACTAL_KERNEL",
  "meta": { "note": "free-form" },
  "kernel": {
    "fractal_seed": {
      "Z_AXIOM": ["axiom 1", "axiom 2"],
      "OMEGA_ATTRACTOR": "one-sentence long-term attractor",
      "guardrails": ["rule that must never be broken"]
    }
  }
}
```

### Reading rules
- A reader MUST use the `kernel` object if present, else treat the whole document as the kernel.
- `Z_AXIOM` (list of strings) — injected verbatim into every reasoning cycle as inviolable premises.
- `OMEGA_ATTRACTOR` (string) — the agent's standing long-term orientation.
- `guardrails` (list of strings) — hard behavioral constraints, injected after axioms.
- A missing kernel file is valid: an agent without a constitution.

### Writing rules
- A kernel is written **by a human or a deliberate process only** — never by the
  agent's own learning loop. That is the whole point.
- Kernel identity hash: `sha256( canonical_json(kernel) )` (see §3). Implementations
  SHOULD report this hash in every reasoning trace so the active constitution is auditable.

---

## 2. State snapshot

```json
{
  "body": {
    "format": "SES_Partitura",
    "version": "5.1",
    "canonicalization": "SES_CANON_JSON_v1",
    "snapshot_ts": "ISO-8601 UTC",
    "nodes": [ <node>, ... ],
    "edges": [ <edge>, ... ],
    "affect": { ... }
  },
  "provenance": {
    "hash": "sha256:<hex of canonical_json(body)>",
    "engine": "<producer id>",
    "emb_model": "<embedding model used>",
    "created": "ISO-8601 UTC"
  }
}
```

### Node
```json
{
  "id": "N42",
  "_text": "the memory content, human-readable",
  "layer": "CORE | GOAL | CONTEXT | EPISODIC",
  "ts": "ISO-8601 UTC",
  "meta": {
    "role": "user | assistant | system",
    "status": "active | archived",
    "salience": 0.5,
    "kind": "lesson | abstraction | pulse | ... (optional)"
  }
}
```

Layer semantics (writing rules):
- `CORE` — distilled knowledge: operator decisions, lessons, consolidated abstractions.
  Never auto-archived.
- `GOAL` — active intentions; drive autonomous behavior.
- `CONTEXT` — accepted thoughts of medium/high quality.
- `EPISODIC` — raw exchanges; subject to decay and nightly consolidation
  (clusters of ≥3 episodic nodes with pairwise cosine > 0.65 are abstracted into one
  CORE node, originals archived).

Embeddings are **not** part of the snapshot body (they are model-specific cache);
the embedding model is recorded in provenance instead.

### Edge
```json
{ "id": "E17", "source": "N42", "target": "N7", "relation": "SUPPORTS", "sim": 0.71 }
```

Relations and the thresholds that create them (cosine of L2-normalized embeddings):

| Relation | Rule |
|---|---|
| `SUPPORTS` | sim > 0.65 |
| `REFINES` | 0.50 < sim ≤ 0.65 |
| `CONTRADICTS` | 0.50 < sim ≤ 0.65 **and** strong negation markers in the new text |
| `ASSOCIATED` | 0.35 < sim ≤ 0.50; also the fallback edge — every node gets at least one edge to its nearest neighbor |

Thresholds above are calibrated for `bge-m3` (1024d). Recalibrate per embedding model;
record the model in provenance.

---

## 3. Canonicalization & integrity (`SES_CANON_JSON_v1`)

```
canonical_json(x) = JSON serialization with:
  - keys sorted lexicographically at every level
  - separators "," and ":" (no whitespace)
  - UTF-8, non-ASCII NOT escaped (ensure_ascii=false)
```

`provenance.hash = "sha256:" + hex( SHA-256( canonical_json(body) ) )`

Verification: recompute over `body`, compare with `provenance.hash`. Any single-character
change in any node fails verification. The hash certifies **integrity** (the snapshot
was not tampered with), not truth.

---

## 4. Compatibility notes

- Unknown fields MUST be preserved on read-modify-write (forward compatibility).
- Unknown layers (e.g. `MEMORY`, `WORKING` from richer implementations) MUST be
  carried through verbatim.
- A reader MUST treat `meta.status == "archived"` nodes as invisible to recall.
