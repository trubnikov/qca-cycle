#!/bin/bash
# QCA pulse: autonomous step toward goals. Empty output = SILENCE = stay quiet.
set -a; source ~/.hermes/.env 2>/dev/null; set +a
export QCA_STORE=~/.hermes/qca/graph.json QCA_LLM_BACKEND=anthropic
OUT=$(python3 ~/.hermes/skills/cognitive/qca-cycle/scripts/qca_engine.py pulse 2>/dev/null)
[ -n "$OUT" ] && [ "$OUT" != "SILENCE" ] && echo "🌊 Autonomous step:
$OUT"
exit 0
