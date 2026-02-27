# amit-claude — personal AI config & skills
# Run `just` to see all targets

home           := env_var("HOME")
skills_src     := justfile_directory() / ".cursor/skills"
skills_link    := home / ".cursor/skills"
claude_src     := justfile_directory() / "CLAUDE.md"
claude_link    := home / ".claude/CLAUDE.md"
templates_src  := justfile_directory() / ".cursor/skills/memory-manager/templates"

# Show available commands
default:
    @just --list

# ── Setup ─────────────────────────────────────────────────────────────────────

# First-time setup on a new machine: create both symlinks (skills + CLAUDE.md)
setup:
    just link-skills
    just link-claude
    @echo ""
    @echo "Setup complete. Run 'just status' to verify."

# Create ~/.cursor/skills → this repo's .cursor/skills/ (live symlink — no sync needed)
link-skills:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -L "{{skills_link}}" ]; then
        current=$(readlink "{{skills_link}}")
        if [ "$current" = "{{skills_src}}" ]; then
            echo "✓ Already linked: {{skills_link}} → {{skills_src}}"
            exit 0
        fi
        echo "Updating existing symlink: $current → {{skills_src}}"
        rm "{{skills_link}}"
    elif [ -d "{{skills_link}}" ]; then
        echo "Backing up existing directory → {{skills_link}}.bak"
        mv "{{skills_link}}" "{{skills_link}}.bak"
    fi
    ln -s "{{skills_src}}" "{{skills_link}}"
    echo "✓ Linked {{skills_link}} → {{skills_src}}"

# Create ~/.claude/CLAUDE.md → this repo's CLAUDE.md (live symlink)
link-claude:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -f "{{claude_link}}" ] && [ ! -L "{{claude_link}}" ]; then
        echo "Backing up existing CLAUDE.md → {{claude_link}}.bak"
        mv "{{claude_link}}" "{{claude_link}}.bak"
    fi
    ln -sf "{{claude_src}}" "{{claude_link}}"
    echo "✓ Linked {{claude_link}} → {{claude_src}}"

# ── Memory Management ─────────────────────────────────────────────────────────

# Initialize full project memory: memory/ files (knowledge store) + Beads (task graph)
# Usage: just memory-init [path]   — defaults to current directory
memory-init path=".":
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{path}}/memory"

    # ── Knowledge store (memory/ files) ────────────────────────────────────
    if [ -d "$target" ]; then
        echo "⚠ $target already exists — skipping knowledge store init"
    else
        mkdir -p "$target"
        cp "{{templates_src}}/CONTEXT.md"        "$target/CONTEXT.md"
        cp "{{templates_src}}/decisions.md"      "$target/decisions.md"
        cp "{{templates_src}}/handoffs.md"       "$target/handoffs.md"
        cp "{{templates_src}}/open-questions.md" "$target/open-questions.md"
        echo "✓ Knowledge store initialized at $target"
    fi

    # ── Task graph (Beads) ──────────────────────────────────────────────────
    if command -v bd &>/dev/null; then
        if [ -d "{{path}}/.beads" ]; then
            echo "⚠ Beads already initialized at {{path}}/.beads — skipping"
        else
            (cd "{{path}}" && bd init)
            echo "✓ Beads task graph initialized (use 'bd ready --json' to see unblocked tasks)"
        fi
    else
        echo ""
        echo "⚠ 'bd' not found — skipping Beads init."
        echo "  Install: bun install -g @beads/bd"
        echo "  Then run: cd {{path}} && bd init"
    fi

    # ── AGENTS.md ───────────────────────────────────────────────────────────
    agents_file="{{path}}/AGENTS.md"
    if [ ! -f "$agents_file" ]; then
        printf '%s\n' \
            "## Task Tracking (Beads)" \
            "" \
            "Use bd for ALL task management — no markdown TODO lists, no external trackers." \
            "  bd ready --json                        start here every session" \
            "  bd update <id> --claim                 claim before starting work" \
            "  bd update <id> --status done           mark complete when done" \
            "  bd create \"Title\" -p N                 create tasks (P0=critical, P3=low)" \
            "  bd dep add <new> <src> --type discovered-from   link all discovered work" \
            "  Planning docs: history/YYYY-MM-DD-<desc>.md  (never in repo root)" \
            "" \
            "## Knowledge Store (memory/)" \
            "" \
            "Read memory/CONTEXT.md first each session." \
            "After finishing: replace your section in memory/handoffs.md" \
            "and append decisions to memory/decisions.md" \
            > "$agents_file"
        echo "✓ AGENTS.md created"
    fi

    echo ""
    echo "Next: edit memory/CONTEXT.md with project name, tech stack, and goals."
    echo "      Then run: bd create 'First task' -p 1"

# Show memory status for a project (usage: just memory-status [path])
memory-status path=".":
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{path}}/memory"
    if [ ! -d "$target" ]; then
        echo "✗ No memory/ directory found at {{path}} — run: just memory-init {{path}}"
        exit 1
    fi
    echo "=== Memory: $target ==="
    echo ""
    echo "--- CONTEXT (last activity) ---"
    grep "Last activity" "$target/CONTEXT.md" || echo "(not set)"
    grep "Current phase" "$target/CONTEXT.md" || echo "(not set)"
    echo ""
    echo "--- Handoffs (last updated per specialist) ---"
    rg -e "^## (PM|Designer|Explorer|Staff|Architect|DevOps|Backend|API|Security|Performance|Mobile|Junior)" "$target/handoffs.md" || echo "(none)"
    echo ""
    echo "--- Open Questions ---"
    rg "Open" "$target/open-questions.md" || echo "(none open)"

# Show full memory context for a project (usage: just memory-show [path])
memory-show path=".":
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{path}}/memory"
    if [ ! -d "$target" ]; then
        echo "✗ No memory/ at {{path}}"
        exit 1
    fi
    echo "════════════════════════════════"
    echo "  CONTEXT"
    echo "════════════════════════════════"
    cat "$target/CONTEXT.md"
    echo ""
    echo "════════════════════════════════"
    echo "  HANDOFFS"
    echo "════════════════════════════════"
    cat "$target/handoffs.md"
    echo ""
    echo "════════════════════════════════"
    echo "  OPEN QUESTIONS"
    echo "════════════════════════════════"
    cat "$target/open-questions.md"

# Reset memory/ for a project — backs up first (usage: just memory-reset [path])
memory-reset path=".":
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{path}}/memory"
    backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
    if [ -d "$target" ]; then
        mv "$target" "$backup"
        echo "✓ Backed up $target → $backup"
    fi
    just memory-init "{{path}}"

# ── Task Management (Beads) ────────────────────────────────────────────────────

# Show unblocked tasks (--json for reliable output) — run before every session
tasks:
    @bd ready --json | jq -r '.[] | "\(.id)\t[P\(.priority)]\t\(.title)"' 2>/dev/null || bd ready

# Create a task (usage: just task "Title" [priority 0-3])
task title priority="1":
    bd create "{{title}}" -p {{priority}}

# Claim a task (usage: just claim <id>)
claim id:
    bd update {{id}} --claim

# Mark a task done, then show what's next (usage: just done <id>)
done id:
    bd update {{id}} --status done
    @echo "Next unblocked:"
    @bd ready --json | jq -r '.[0:3] | .[] | "  \(.id)  \(.title)"' 2>/dev/null || bd ready

# Show full task details as JSON (usage: just task-show <id>)
task-show id:
    @bd show {{id}} --json | jq .

# List all in-progress tasks
in-progress:
    @bd list --status in_progress --json | jq -r '.[] | "\(.id)\t\(.title)"' 2>/dev/null || bd list --status in_progress

# ── Status / Verify ───────────────────────────────────────────────────────────

# Show symlink status for both skills and CLAUDE.md
status:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "=== Skills symlink ==="
    if [ -L "{{skills_link}}" ]; then
        target=$(readlink "{{skills_link}}")
        if [ "$target" = "{{skills_src}}" ]; then
            echo "✓ {{skills_link}} → $target"
            echo "  ($(ls "{{skills_link}}" | wc -l | tr -d ' ') skills)"
        else
            echo "⚠ {{skills_link}} → $target  (expected {{skills_src}})"
        fi
    else
        echo "✗ {{skills_link}} is not a symlink — run: just link-skills"
    fi

    echo ""
    echo "=== CLAUDE.md symlink ==="
    if [ -L "{{claude_link}}" ]; then
        target=$(readlink "{{claude_link}}")
        if [ "$target" = "{{claude_src}}" ]; then
            echo "✓ {{claude_link}} → $target"
        else
            echo "⚠ {{claude_link}} → $target  (expected {{claude_src}})"
        fi
    else
        echo "✗ {{claude_link}} is not a symlink — run: just link-claude"
    fi

# Verify both symlinks are correct (exits non-zero if either is broken)
check:
    #!/usr/bin/env bash
    set -euo pipefail
    errors=0

    if [ ! -L "{{skills_link}}" ]; then
        echo "✗ {{skills_link}} is not a symlink — run: just link-skills"
        errors=$((errors+1))
    else
        target=$(readlink "{{skills_link}}")
        if [ "$target" != "{{skills_src}}" ]; then
            echo "✗ Skills wrong target: $target (expected {{skills_src}})"
            errors=$((errors+1))
        else
            echo "✓ Skills symlink OK  ($(ls "{{skills_link}}" | wc -l | tr -d ' ') skills)"
        fi
    fi

    if [ ! -L "{{claude_link}}" ]; then
        echo "✗ {{claude_link}} is not a symlink — run: just link-claude"
        errors=$((errors+1))
    else
        target=$(readlink "{{claude_link}}")
        if [ "$target" != "{{claude_src}}" ]; then
            echo "✗ CLAUDE.md wrong target: $target (expected {{claude_src}})"
            errors=$((errors+1))
        else
            echo "✓ CLAUDE.md symlink OK"
        fi
    fi

    exit $errors
