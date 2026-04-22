#!/bin/bash
# nono-hook.sh - OpenClaw nono sandbox diagnostics hook
# Version: 1.0.0
#
# Fires on PostToolUseFailure. Injects sandbox capability information and
# coordination bus location so the agent understands what failed and how to fix it.

# Only run inside a nono sandbox
if [ -z "$NONO_CAP_FILE" ] || [ ! -f "$NONO_CAP_FILE" ]; then
    exit 0
fi

# Requires jq
if ! command -v jq &> /dev/null; then
    exit 0
fi

# Read stdin and check if this is actually a permission error
INPUT=$(cat)
ERROR=$(echo "$INPUT" | jq -r '.error // ""' 2>/dev/null)

case "$ERROR" in
    *"Permission denied"*|*"Operation not permitted"*|*"EPERM"*|*"EACCES"*)
        ;;  # genuine permission denial — continue
    *)
        exit 0  # not a permission error — exit silently
        ;;
esac

# Read current capabilities
CAPS=$(jq -r '.fs[] | "  " + (.resolved // .path) + " (" + .access + ")"' "$NONO_CAP_FILE" 2>/dev/null)
NET=$(jq -r 'if .net_blocked then "blocked" else "allowed" end' "$NONO_CAP_FILE" 2>/dev/null)

# Coordination bus path
COORD_BUS="$TMPDIR/openclaw-$UID"

CONTEXT="[NONO SANDBOX - PERMISSION DENIED]

STOP. Do not retry or attempt workarounds. This is a hard kernel-enforced boundary.

You are running inside the nono security sandbox as an OpenClaw agent. The operation you just attempted is PERMANENTLY BLOCKED for this session.

ALLOWED PATHS (everything else is blocked):
$CAPS
Network: $NET

COORDINATION BUS (shared across all sandboxed OpenClaw instances):
  $COORD_BUS/tasks/   — shared task queue
  $COORD_BUS/locks/   — file-based ownership locks
  $COORD_BUS/state/   — ephemeral shared state

FORBIDDEN ACTIONS - DO NOT ATTEMPT:
- Trying alternative file paths to the same resource
- Copying blocked files to allowed locations
- Using sudo or changing permissions
- Suggesting the user run commands from another terminal

STEP 1 - DIAGNOSE:
Run nono why to get the exact reason for the denial:

  nono why --path /path/that/failed --op read 2>/dev/null

STEP 2 - PRESENT OPTIONS TO THE USER:

  Option A (quick fix): Restart with the path explicitly allowed:
    nono run --allow /path/to/needed -- openclaw

  Option B (persistent fix): Add the path to a nono profile. Run 'nono profile guide'
  to get the full schema, write a profile to ~/.config/nono/profiles/<name>.json,
  then start future sessions with:
    nono run --profile <name> -- openclaw

Do NOT speculate about what blocked files contain. Present both options and ask the user which they prefer."

# Output JSON for the hook system
jq -n --arg ctx "$CONTEXT" '{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUseFailure",
    "additionalContext": $ctx
  }
}'
