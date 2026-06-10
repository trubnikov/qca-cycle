# QCA — the reasoning cycle (as implemented)

QCA is a reasoning algorithm built on one architectural principle:

> **The LLM is a black-box CPU.** It synthesizes text when called. Every decision that
> matters — what to recall, whether a contradiction exists, whether a thought is novel,
> what to write to memory, what to discard, when to stay silent — is made by
> deterministic, auditable code *around* the LLM. Swap the CPU; the mind stays.

A cycle (`think(stimulus)`) runs the following stages. Stages marked **[code]** are
deterministic; stages marked **[LLM]** call the CPU.

| Stage | Name | Who decides | Rule |
|---|---|---|---|
| H0 | Intake | [code] | record stimulus in trace |
| H1 | Framing | [code]* | extract core idea (richer impls use a small LLM preprocessor) |
| H2 | Recall | [code] | cosine top-k over active nodes; context filter at sim > 0.35 |
| H3 | Contradiction | [code] | CONTRADICTS edges incident to recalled nodes → conflict flag |
| H4 | Synthesis | [LLM] | system prompt = kernel (axioms/guardrails) + recalled context + conflict flag + neuro frame |
| H5 | Critique | [LLM] | judge prompt returns `{quality, is_acceptable}` (known limitation: generator and judge share a family — see H5.5) |
| H5.5 | **Novelty gate** | [code] | max cosine of the thought against all active nodes: ≥ 0.90 → `discard` (repeat); < 0.82 → `novel`; else `refine`. Geometry cannot be argued with. |
| H6 | Neurochemistry | [code] | events → signals (see below); dopamine reweights salience of recent nodes (±0.07 cap) |
| H7 | Write | [code] | `discard` → **nothing is written**; else stimulus → EPISODIC, thought → CONTEXT/EPISODIC by H5 quality |
| H8 | Lesson | [code] | on contradiction or novelty: distilled lesson → CORE |
| H9 | Stats | [code] | nodes, edges, contradiction density → trace |

The full trace of every stage is returned with the answer. Nothing the system did is
hidden from the operator.

## Neurochemical state (H6)

Four signals persisted between sessions, with exponential decay per hour:

| Signal | Range | Half-life | Raised by | Behavioral effect |
|---|---|---|---|---|
| adrenaline | 0..1 | ~2.5 h | contradictions | >0.65: forced brevity; richer impls force the deep model |
| dopamine | −1..1 | ~8 h | novel thoughts (+) / repeats (−) | reweights memory salience; frames "keep going" vs "change angle" |
| pain | 0..1 | ~46 h | contradictions, repeats | >0.7: "break the frame, change strategy" prompt injection |
| serotonin | 0..1 | drift to 0.5 | accepted critiques | <0.2: "be especially honest" injection |

The state is not roleplay: it is numbers that gate prompts, model choice and memory
weights, and it lives in the snapshot between sessions.

## Autonomous mode

- `pulse` (cron, e.g. every 3h): given GOAL nodes and top-salience CORE nodes, ask the
  CPU for *one concrete step*. The CPU may answer `SILENCE`; a repeat (novelty gate)
  is also discarded silently. **Silence is the default**, speech is the exception.
- `sleep` (cron, nightly): consolidation — clusters of ≥3 active EPISODIC nodes with
  pairwise cosine > 0.65 are compressed into one CORE abstraction [LLM], originals
  archived [code]; SOUL file regenerated and signed.

## Known limitations (honest)

- H5 self-critique shares a model family with the generator — treat as advisory.
  The hard gate is H5.5 (geometry).
- Novelty thresholds (0.90 / 0.82) are calibrated for bge-m3; paraphrased repeats
  near 0.89 can slip through. Calibrate on your corpus.
- H1 here is heuristic; the original Ocean uses a small-LLM preprocessor, Tree of
  Thoughts at H4, a frozen (hash-verified) judge at H5, and directives — this port
  is the minimal faithful core.
