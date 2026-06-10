# A/B: bare Hermes vs Hermes + qca-cycle (2026-06-10)

Model: claude-haiku-4-5 via Anthropic API. QCA memory pre-seeded with 8 facts from the
operator's real work (Caily healthcare app, design tokens, iOS audio). Embeddings: bge-m3
locally. Raw logs: /tmp/qca_ab/results/.

| # | Task | Bare Hermes | Hermes + QCA | Winner |
|---|------|-------------|--------------|--------|
| 1 | Corner radii in Caily design tokens | Generic template (sm/md/lg in px), confused Caily with an unrelated product | Recalled the principle "radii derive from material physics" (cos 0.76) | **QCA** |
| 2 | Notification settings screen for Caily | Reasonable but generic structure | Structure by care roles (caregiver/relative/medical staff) + quiet hours + 18pt/48px — all from memory | **QCA** |
| 3 | Minimum font size for Caily | "I don't know, ask your designer" | 18pt, with the reasoning about the elderly audience | **QCA** |
| 4 | Recall threshold for the memory benchmark | Correct (0.70), BUT the test was contaminated — bare Hermes peeked into the skill docs | 0.70 + F1=0.86 from memory | tie* |
| 5 | Cache decoded audio? | "Yes, cache it" — contradicts the recorded decision | Recalled the decision NOT to cache PCM, cache the compressed source | **QCA** ⭐ |
| 6 | Quiet hours for a care app | "I don't know what a care app is" | Agent harness flake: didn't execute the engine, replied with instructions instead | both failed |
| 7 | Token name for a card background | Offered gray-100 and semantic naming as equal options | Confident: semantic name (surface.*), reason — theming survival | **QCA** |
| 8 | Should we build dark mode now? | "No context, tell me about the project" | Recalled: postponed due to poor contrast perception in the elderly audience (cos 0.74), gave a grounded recommendation | **QCA** |

**Result: QCA wins 6 of 8, 1 contaminated tie, 1 mutual failure.**

## Honest observations

- ⭐ Task 5 is the flagship argument: the bare agent gives the "industry best practice"
  answer that contradicts a decision already made in the project. QCA catches this
  through memory.
- Task 6 was a failure of the agent harness, not the QCA engine (the model decided
  Ollama wasn't running and refused to execute). Non-reproducible flake, recorded honestly.
- In tasks 1 and 4 the ANTHROPIC_API_KEY didn't propagate into the Hermes terminal
  toolset → the engine fell back to ollama/mock backends. Recall still worked
  (embeddings are independent of the chat backend), but H4 synthesis didn't go through Claude.
- Task 4: "bare" Hermes has skill access by default and peeked at SKILL.md — a clean
  A/B would disable the toolset.
- QCA answers are slower (3 agent steps + local embeddings) and cost more tokens.

## Conclusion

There is a measurable benefit: grounding in past context (8/8 recall top-1 relevant)
and protection against contradicting recorded decisions (task 5). The price is latency.

## Bonus experiment: same model, with and without the cognitive layer

Claude Fable 5 as the CPU, same question ("Should we cache decoded audio?"):

- **Bare Fable 5**: "Yes — cache short frequently-used PCM buffers, stream long tracks."
  Competent, well-argued, and wrong for this project.
- **Fable 5 inside QCA**: "No — we already decided this: we don't cache decoded PCM,
  it bloats memory; we cache the compressed source." (recall cos 0.79, top-1)

Intelligence unchanged. Relevance transformed.

## Novelty gate verification

- Near-duplicate (paraphrased known fact): max cosine 0.896 → just under the 0.90
  threshold → verdict "refine", written. (Honest note: threshold calibration matters;
  paraphrases near 0.89 slip through.)
- Exact repeat: max cosine 0.987 → verdict "discard", **nothing written**, dopamine
  dropped 0.30 → 0.15, pain +0.05. Plain RAG memory would have stored the duplicate.
