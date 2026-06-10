#!/bin/bash
# QCA nightly sleep: memory consolidation + SOUL refresh + SES snapshot.
set -a; source ~/.hermes/.env 2>/dev/null; set +a
export QCA_STORE=~/.hermes/qca/graph.json QCA_LLM_BACKEND=anthropic
E=~/.hermes/skills/cognitive/qca-cycle/scripts/qca_engine.py
R=$(python3 $E sleep 2>/dev/null)
python3 $E soul > /dev/null 2>&1
python3 ~/.hermes/skills/cognitive/qca-cycle/scripts/ses_bridge.py export-skills > /dev/null 2>&1
CL=$(echo "$R" | python3 -c "import json,sys; print(json.load(sys.stdin).get('clusters',0))" 2>/dev/null)
[ "$CL" != "0" ] && [ -n "$CL" ] && echo "🌙 Nightly cycle complete:
$R"
exit 0
