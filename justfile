# amit-claude — personal AI config & skills
# Run `just` to see all targets

home           := env_var("HOME")
skills_src     := ".cursor/skills"
skills_dest    := home / ".cursor/skills"
claude_src     := justfile_directory() / "CLAUDE.md"
claude_link    := home / ".claude/CLAUDE.md"
templates_src  := justfile_directory() / ".cursor/skills/memory-manager/templates"

# Show available commands
default:
    @just --list

# ── Setup ─────────────────────────────────────────────────────────────────────

# First-time setup on a new machine: link CLAUDE.md + sync all skills
setup:
    just link-claude
    just sync-cursor
    @echo ""
    @echo "Setup complete. Run 'just status' to verify."

# Create ~/.claude/CLAUDE.md symlink pointing to this repo
link-claude:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -f "{{claude_link}}" ] && [ ! -L "{{claude_link}}" ]; then
        echo "Backing up existing CLAUDE.md → {{claude_link}}.bak"
        mv "{{claude_link}}" "{{claude_link}}.bak"
    fi
    ln -sf "{{claude_src}}" "{{claude_link}}"
    echo "✓ Linked {{claude_link}} → {{claude_src}}"

# ── Sync ──────────────────────────────────────────────────────────────────────

# Sync all Cursor skills to ~/.cursor/skills/
sync-cursor:
    @echo "Syncing all skills to {{skills_dest}}..."
    @mkdir -p "{{skills_dest}}"
    @cp -r {{skills_src}}/* "{{skills_dest}}/"
    @echo "✓ Skills synced:"
    @ls "{{skills_dest}}"

# Sync a single skill to ~/.cursor/skills/ (usage: just sync-skill staff-test-engineer)
sync-skill name:
    @echo "Syncing '{{name}}'..."
    @mkdir -p "{{skills_dest}}"
    @cp -r "{{skills_src}}/{{name}}" "{{skills_dest}}/"
    @echo "✓ Done — {{skills_dest}}/{{name}}"

# Sync the orchestrator + team-standards (run after any standards change)
sync-standards:
    just sync-skill qa-team-orchestrator
    @echo "✓ Standards synced"

# ── Memory Management ─────────────────────────────────────────────────────────

# Initialize full project memory: memory/ files (knowledge store) + Beads (task graph)
# Usage: just memory-init [path]   — defaults to current directory
memory-init path=".":
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{path}}/memory"

    # ── Layer 2: knowledge store (memory/ files) ────────────────────────────
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

    # ── Layer 1: task graph (Beads) ─────────────────────────────────────────
    if command -v bd &>/dev/null; then
        if [ -d "{{path}}/.beads" ]; then
            echo "⚠ Beads already initialized at {{path}}/.beads — skipping"
        else
            (cd "{{path}}" && bd init)
            echo "✓ Beads task graph initialized (use 'bd ready' to see unblocked tasks)"
        fi
    else
        echo ""
        echo "⚠ 'bd' not found — skipping Beads init."
        echo "  Install: bun install -g @beads/bd"
        echo "  Then run: cd {{path}} && bd init"
    fi

    # ── AGENTS.md hint ───────────────────────────────────────────────────────
    agents_file="{{path}}/AGENTS.md"
    if [ ! -f "$agents_file" ]; then
        printf '%s\n' \
            "## Task Tracking (Beads)" \
            "" \
            "Use bd for all task management:" \
            "  bd ready                        start here every session" \
            "  bd update <id> --claim          claim before starting work" \
            "  bd update <id> --status done    mark complete when done" \
            "  bd create \"Title\" -p N          create tasks (P0=critical, P3=low)" \
            "  bd dep add <child> <parent>     link blocking dependencies" \
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
    grep -E "^## (PM|Designer|Explorer|Staff|Architect|DevOps|Backend|API|Security|Performance|Mobile|Junior)" "$target/handoffs.md" || echo "(none)"
    echo ""
    echo "--- Open Questions ---"
    grep -v "^#\|^|\s*#\|^$" "$target/open-questions.md" | grep "Open" || echo "(none open)"

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

# Show unblocked tasks — run this at the start of every session
tasks:
    @bd ready

# Create a task (usage: just task "Title" [priority])  priority: 0-3, default 1
task title priority="1":
    bd create "{{title}}" -p {{priority}}

# Claim a task and mark it in_progress (usage: just claim <id>)
claim id:
    bd update {{id}} --claim

# Mark a task done (usage: just done <id>)
done id:
    bd update {{id}} --status done

# Show full task details (usage: just task-show <id>)
task-show id:
    bd show {{id}}

# List all in-progress tasks
in-progress:
    @bd list --status in_progress

# ── Status / Verify ───────────────────────────────────────────────────────────

# Show sync status of CLAUDE.md symlink and Cursor skills
status:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "=== CLAUDE.md ==="
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

    echo ""
    echo "=== Global Cursor skills ({{skills_dest}}) ==="
    if [ -d "{{skills_dest}}" ]; then
        ls "{{skills_dest}}"
    else
        echo "✗ Directory not found — run: just sync-cursor"
    fi

    echo ""
    echo "=== Local skills ({{skills_src}}) ==="
    ls "{{skills_src}}"

    echo ""
    echo "=== Diff (local vs global) ==="
    diff <(ls "{{skills_src}}") <(ls "{{skills_dest}}") && echo "✓ In sync" || echo "⚠ Out of sync — run: just sync-cursor"

# Verify CLAUDE.md symlink is correct (exits non-zero if broken)
check:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -L "{{claude_link}}" ]; then
        echo "✗ {{claude_link}} is not a symlink"
        exit 1
    fi
    target=$(readlink "{{claude_link}}")
    if [ "$target" != "{{claude_src}}" ]; then
        echo "✗ Wrong target: $target (expected {{claude_src}})"
        exit 1
    fi
    echo "✓ CLAUDE.md symlink OK"
    echo "✓ Skills: $(ls {{skills_dest}} | wc -l | tr -d ' ') global, $(ls {{skills_src}} | wc -l | tr -d ' ') local"
