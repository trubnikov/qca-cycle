# SES Partitura v5.1 — snapshot format (engine profile)

SES (Somatic-Exosomatic Serialization) is a format for an agent's **identity and memory
as verifiable data**. The canonical specification, JSON Schema, examples and the Kernel
Interview live at **[github.com/trubnikov/SES](https://github.com/trubnikov/SES)**.
This document summarizes the spec and states exactly how `qca_engine.py` implements it,
including declared extensions.

## The main axiom

> **Kernel** answers *"how to think"*. **State** answers *"what to think about right now"*.
> **COMBINED = Kernel + State** → a full cold-boot package.

The separation is the core design decision: identity must not drift as a side effect
of experience. The kernel changes only by a deliberate new snapshot — which produces
a new hash, making personality evolution *versioned* like code.

**Why "fractal"**: the kernel is not a list of preferences — it is a small set of
scale-invariant axioms. The same axioms are expected to resolve a one-line reply and
a life-strategy decision alike; the constitution unfolds self-similarly at every scale
of reasoning. The kernel is the generator; the state is what it generated and lived through.

---

## 1. Universal container (`.ses.json`)

```json
{
  "initiator": "∮",
  "schema_version": "5.1",
  "entity_id": "stable_entity_id",
  "snapshot_id": "ISO-8601 with timezone",
  "snapshot_type": "FRACTAL_KERNEL | STATE_SNAPSHOT | COMBINED",
  "meta": { },
  "kernel": { },
  "state": { }
}
```

Validity invariants:
- `FRACTAL_KERNEL` ⇒ `kernel` required, `state` absent
- `STATE_SNAPSHOT` ⇒ `state` required, `kernel` absent
- `COMBINED` ⇒ both required

### Top-level `meta`

```json
{
  "created_at": "ISO-8601", "created_by": "Operator | System | Import",
  "parent_snapshot_id": "previous_snapshot_id_or_null",
  "kernel_ref": "kernel://entity@location", "kernel_hash": "sha256:...",
  "hash": "sha256:...", "canonicalization": "SES_CANON_JSON_v1",
  "notes": "...", "tags": []
}
```

### The canon lock (§12 of the spec)

> **Every STATE_SNAPSHOT must reference its Kernel** via `meta.kernel_ref` and/or
> `meta.kernel_hash`. The biography must know which constitution lived it.
> This is what makes a snapshot reproducible rather than "just pretty JSON".

The engine enforces this: every exported state carries `kernel_hash` + `kernel_ref`
whenever a kernel is present, and `verify` warns on states without the reference.
`parent_snapshot_id` chains snapshots into an auditable lineage.

---

## 2. Kernel (FRACTAL_KERNEL)

```json
{
  "fractal_seed": {
    "Z_AXIOM": ["scale-invariant axioms"],
    "OMEGA_ATTRACTOR": "one-sentence long-term attractor",
    "guardrails": ["hard constraints"]
  },
  "recursive_function": [
    { "id": "H0", "name": "Ingestion", "input": "...", "output": "...", "rules": ["..."] }
  ],
  "distortion_field": { "items": [
    { "trigger": "...", "effect": "...", "severity": 0.7, "mitigation": ["..."], "examples": ["..."] }
  ]},
  "interfaces": { "inputs": [], "outputs": [], "tools_allowed": [] }
}
```

- `fractal_seed`, `recursive_function`, `distortion_field` are required; steps are
  **objects, not strings** (v5.1).
- A kernel is written **by a human or a deliberate process only** — never by the
  agent's own learning loop.
- `kernel_hash = sha256(canonical_json(kernel))`. The engine reports it in every
  reasoning trace, and injects **all three sections** into every cycle: axioms +
  guardrails, the reasoning protocol, and known distortions with mitigations
  (the agent is told its own failure modes so it can self-correct).

## 3. State

```json
{
  "meta": { "trigger": "user_input | scheduled | import | inference",
            "summary": "...", "provenance": { } },
  "nodes": [ ], "edges": [ ]
}
```

### Node

```json
{ "id": "n01", "label": "content", "glyph": "Ψ (optional)",
  "layer": "CORE | CONTEXT | EPISODIC | MEMORY | GOAL",
  "meta": { "provenance": { }, "salience": 0.9, "status": "active | dormant | archived", "tags": [] } }
```

`id`, `label`, `layer`, `meta.provenance` are **required**.

Layer semantics as the engine writes them: `CORE` — distilled knowledge (operator
decisions, lessons, consolidated abstractions; never auto-archived), `GOAL` — active
intentions driving autonomous behavior, `CONTEXT` — accepted thoughts, `EPISODIC` —
raw exchanges (subject to nightly consolidation: clusters of ≥3 with pairwise
cosine > 0.65 → one CORE abstraction, originals archived).

### Edge

```json
{ "id": "e01", "source": "n02", "target": "n01",
  "relation": "SUPPORTS | CAUSES | DEPENDS_ON | CONTRADICTS | REFINES | ASSOCIATED",
  "meta": { "provenance": { }, "weight": 0.71 } }
```

`source`, `target`, `relation`, `meta.provenance` are **required**. The engine sets
`weight` from embedding cosine and creates edges by thresholds (calibrated for bge-m3):
SUPPORTS > 0.65, REFINES 0.50–0.65, CONTRADICTS 0.50–0.65 + negation markers,
ASSOCIATED 0.35–0.50 (and as the guaranteed fallback edge).

### Provenance (required on every node and edge)

```json
{ "source": "GENESIS | OPERATOR | QCA_CYCLE | IMPORT | INFERENCE",
  "stage": "H0..H9 | E1 | BOOT", "timestamp": "ISO-8601",
  "source_ref": [], "confidence": 1.0 }
```

`confidence`: 1.0 = fact/canon, 0.5 = plausible reconstruction, 0.2 = hypothesis.

---

## 4. Canonicalization & hashes (`SES_CANON_JSON_v1`)

- Object keys sorted lexicographically; compact separators; UTF-8 not escaped.
- `nodes` sorted by `id`; `edges` sorted by `id`, else by `(source, target, relation)`.
- Timestamps ISO-8601.
- `meta.hash` = SHA-256 of the canonical JSON of the whole snapshot, computed with
  `meta.hash` itself absent. `meta.kernel_hash` = SHA-256 of the canonical kernel only.

Verification: recompute, compare. Any single-character change fails loudly. The hash
certifies **integrity** (not tampered), not truth.

---

## 5. Engine extensions (declared, `x_`-prefixed)

The engine adds one extension field, ignored by canonical readers:

- `state.meta.x_neuro` — the neurochemical state at snapshot time
  (`dopamine`, `pain`, `adrenaline`, `serotonin`).

Internal working storage (`graph.json`) is private to the engine and not part of the
format; SES snapshots are the interchange and provenance layer.

## 6. Compatibility rules

- Unknown fields MUST be preserved on read-modify-write.
- Unknown layers (e.g. `WORKING` from richer implementations) MUST be carried through.
- Nodes with `status: "archived"` are invisible to recall.
- Legacy snapshots (pre-canonical `body`/`provenance` wrapper) are still verifiable
  by `ses_bridge.py verify`, which detects the format automatically.
