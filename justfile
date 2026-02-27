# amit-claude — personal AI config & skills
# Run `just` to see all targets

# Colors (defined once, used via {{g}}/{{y}}/{{r}}/{{n}} substitution in all recipes)
g := `printf '\033[32m'`
y := `printf '\033[33m'`
r := `printf '\033[31m'`
n := `printf '\033[0m'`

home           := env_var("HOME")
skills_src     := justfile_directory() / ".cursor/skills"
skills_link    := home / ".cursor/skills"
rules_src      := justfile_directory() / ".cursor/rules"
rules_link     := home / ".cursor/rules"
claude_src      := justfile_directory() / "CLAUDE.md"
claude_link     := home / ".claude/CLAUDE.md"
settings_src    := justfile_directory() / "config/claude-settings.json"
settings_link   := home / ".claude/settings.json"
templates_src   := justfile_directory() / ".cursor/skills/memory-manager/templates"
discord_config  := justfile_directory() / "config/discord.env"

# Show available commands
default:
    @just --list

# ── Setup ─────────────────────────────────────────────────────────────────────

# First-time setup: create all symlinks and add the 'ai' alias to ~/.zshrc
setup:
    #!/usr/bin/env bash
    set -euo pipefail

    symlink() {
        local src="$1" dst="$2"
        if [ -L "$dst" ]; then
            rm "$dst"                          # remove existing symlink before re-linking
        elif [ -e "$dst" ]; then
            mv "$dst" "${dst}.bak" && echo "  {{y}}backed up${n} ${dst}.bak"
        fi
        ln -s "$src" "$dst"
        echo "{{g}}✓{{n}} $dst → $src"
    }

    symlink "{{skills_src}}"   "{{skills_link}}"
    symlink "{{rules_src}}"    "{{rules_link}}"
    symlink "{{claude_src}}"   "{{claude_link}}"
    symlink "{{settings_src}}" "{{settings_link}}"

    alias_line="alias ai='just -f {{justfile()}}'"
    if grep -qF "$alias_line" "$HOME/.zshrc" 2>/dev/null; then
        echo "{{g}}✓{{n}} 'ai' alias already in ~/.zshrc"
    else
        printf '\n# amit-claude\n%s\n' "$alias_line" >> "$HOME/.zshrc"
        echo "{{g}}✓{{n}} Added 'ai' alias to ~/.zshrc — run: source ~/.zshrc"
    fi

    echo ""
    echo "{{g}}Done.{{n}} Run 'just status' to verify."

# ── Memory Management ─────────────────────────────────────────────────────────

# Initialize full project memory: memory/ files (knowledge store) + Beads (task graph)
# Usage: ai memory-init [path]   — defaults to the directory where ai was invoked
memory-init path=invocation_directory():
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{path}}/memory"

    # ── Knowledge store (memory/ files) ────────────────────────────────────
    if [ -d "$target" ]; then
        echo "{{y}}⚠{{n}} $target already exists — skipping knowledge store init"
    else
        mkdir -p "$target"
        cp "{{templates_src}}/CONTEXT.md"        "$target/CONTEXT.md"
        cp "{{templates_src}}/decisions.md"      "$target/decisions.md"
        cp "{{templates_src}}/handoffs.md"       "$target/handoffs.md"
        cp "{{templates_src}}/open-questions.md" "$target/open-questions.md"
        echo "{{g}}✓{{n}} Knowledge store initialized at $target"
    fi

    # ── Task graph (Beads) ──────────────────────────────────────────────────
    if command -v bd &>/dev/null; then
        if [ -d "{{path}}/.beads" ]; then
            echo "{{y}}⚠{{n}} Beads already initialized at {{path}}/.beads — skipping"
        else
            (cd "{{path}}" && bd init)
            echo "{{g}}✓{{n}} Beads task graph initialized (use 'bd ready --json' to see unblocked tasks)"
        fi
    else
        echo ""
        echo "{{y}}⚠{{n}} 'bd' not found — skipping Beads init."
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
        echo "{{g}}✓{{n}} AGENTS.md created"
    fi

    echo ""
    echo "Next: edit memory/CONTEXT.md with project name, tech stack, and goals."
    echo "      Then run: bd create 'First task' -p 1"

# Show memory status for a project (usage: just memory-status [path])
memory-status path=invocation_directory():
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{path}}/memory"
    if [ ! -d "$target" ]; then
        echo "{{r}}✗{{n}} No memory/ directory found at {{path}} — run: just memory-init {{path}}"
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
memory-show path=invocation_directory():
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{path}}/memory"
    if [ ! -d "$target" ]; then
        echo "{{r}}✗{{n}} No memory/ at {{path}}"
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
memory-reset path=invocation_directory():
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{path}}/memory"
    backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
    if [ -d "$target" ]; then
        mv "$target" "$backup"
        echo "{{g}}✓{{n}} Backed up $target → $backup"
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

# Show symlink status
status:
    #!/usr/bin/env bash
    set -euo pipefail
    check() {
        local label="$1" link="$2" expected="$3"
        if [ -L "$link" ]; then
            actual=$(readlink "$link")
            count=""; [ -d "$link" ] && count="  ($(ls "$link" | wc -l | tr -d ' ') files)"
            [ "$actual" = "$expected" ] && echo "{{g}}✓{{n}} $label: $link → $actual$count" \
                                        || echo "{{y}}⚠{{n}} $label: wrong target $actual (expected $expected)"
        else
            echo "{{r}}✗{{n}} $label: $link is not a symlink — run: just setup"
        fi
    }
    check "Cursor skills"   "{{skills_link}}"   "{{skills_src}}"
    check "Cursor rules"    "{{rules_link}}"    "{{rules_src}}"
    check "CLAUDE.md"       "{{claude_link}}"   "{{claude_src}}"
    check "Claude settings" "{{settings_link}}" "{{settings_src}}"

# ── Discord Notifications ─────────────────────────────────────────────────────
# Config: copy config/discord.env.example → config/discord.env and fill in webhooks.
# All targets are no-ops if config/discord.env does not exist (safe to call unconditionally).

# Send a plain-text message to the updates channel
# Usage: just notify "message"
notify msg:
    #!/usr/bin/env bash
    set -euo pipefail
    cfg="{{discord_config}}"
    if [ ! -f "$cfg" ]; then
        echo "{{y}}⚠{{n}} Discord not configured — copy config/discord.env.example → config/discord.env"
        exit 0
    fi
    source "$cfg"
    url="${DISCORD_WEBHOOK_UPDATES:-}"
    if [ -z "$url" ]; then echo "{{y}}⚠{{n}} DISCORD_WEBHOOK_UPDATES not set in $cfg"; exit 0; fi
    username="${DISCORD_USERNAME:-amit-ai-team}"
    avatar="${DISCORD_AVATAR_URL:-}"
    payload=$(jq -n \
        --arg content "{{msg}}" \
        --arg username "$username" \
        --arg avatar "$avatar" \
        '{content: $content, username: $username} + (if $avatar != "" then {avatar_url: $avatar} else {} end)')
    curl -s -o /dev/null -w "%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$payload" | grep -q "^2" && echo "{{g}}✓{{n}} Discord notification sent" || echo "{{r}}✗{{n}} Discord POST failed"

# Send an alert to the alerts channel (falls back to updates channel)
# Usage: just alert "message"
alert msg:
    #!/usr/bin/env bash
    set -euo pipefail
    cfg="{{discord_config}}"
    if [ ! -f "$cfg" ]; then
        echo "{{y}}⚠{{n}} Discord not configured — copy config/discord.env.example → config/discord.env"
        exit 0
    fi
    source "$cfg"
    url="${DISCORD_WEBHOOK_ALERTS:-${DISCORD_WEBHOOK_UPDATES:-}}"
    if [ -z "$url" ]; then echo "{{y}}⚠{{n}} No alert webhook set in $cfg"; exit 0; fi
    username="${DISCORD_USERNAME:-amit-ai-team}"
    avatar="${DISCORD_AVATAR_URL:-}"
    payload=$(jq -n \
        --arg content ":warning: {{msg}}" \
        --arg username "$username" \
        --arg avatar "$avatar" \
        '{content: $content, username: $username} + (if $avatar != "" then {avatar_url: $avatar} else {} end)')
    curl -s -o /dev/null -w "%{http_code}" -X POST "$url" \
        -H "Content-Type: application/json" \
        -d "$payload" | grep -q "^2" && echo "{{g}}✓{{n}} Discord alert sent" || echo "{{r}}✗{{n}} Discord POST failed"

# Post latest handoff summary from memory/handoffs.md to Discord
# Usage: just notify-handoff [agent] [path]   agent defaults to last updated section, path to "."
notify-handoff agent="" path=invocation_directory():
    #!/usr/bin/env bash
    set -euo pipefail
    handoffs="{{path}}/memory/handoffs.md"
    if [ ! -f "$handoffs" ]; then
        echo "{{r}}✗{{n}} No memory/handoffs.md at {{path}} — run: just memory-init {{path}}"
        exit 1
    fi
    if [ -n "{{agent}}" ]; then
        # Extract the named agent's section (from its ## heading to the next ##)
        msg=$(awk '/^## {{agent}}/{found=1} found && /^## / && !/^## {{agent}}/{exit} found{print}' "$handoffs" | head -30)
    else
        # Use the last 20 lines of the file (most recently updated section)
        msg=$(tail -20 "$handoffs")
    fi
    if [ -z "$msg" ]; then
        echo "{{y}}⚠{{n}} No handoff content found for agent '{{agent}}'"
        exit 0
    fi
    just notify "$msg"

# Post task completion notice to Discord
# Usage: just notify-done <task-id>
notify-done id:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v bd &>/dev/null; then
        echo "{{y}}⚠{{n}} bd not found"; exit 0
    fi
    info=$(bd show {{id}} --json 2>/dev/null | jq -r '"Task done: [" + .id + "] " + .title + " (P" + (.priority|tostring) + ")"' 2>/dev/null || echo "Task {{id}} marked done")
    just notify "$info"

# Show Discord config status
discord-status:
    #!/usr/bin/env bash
    cfg="{{discord_config}}"
    if [ ! -f "$cfg" ]; then
        echo "{{r}}✗{{n}} config/discord.env not found"
        echo "  Setup: cp config/discord.env.example config/discord.env"
        echo "         then fill in your webhook URL(s)"
        exit 0
    fi
    source "$cfg"
    echo "=== Discord config ($cfg) ==="
    echo ""
    [ -n "${DISCORD_WEBHOOK_UPDATES:-}" ] && echo "{{g}}✓{{n}} DISCORD_WEBHOOK_UPDATES  set" || echo "{{r}}✗{{n}} DISCORD_WEBHOOK_UPDATES  not set"
    [ -n "${DISCORD_WEBHOOK_ALERTS:-}"  ] && echo "{{g}}✓{{n}} DISCORD_WEBHOOK_ALERTS   set" || echo "  DISCORD_WEBHOOK_ALERTS   not set (falls back to UPDATES)"
    [ -n "${DISCORD_USERNAME:-}"        ] && echo "{{g}}✓{{n}} DISCORD_USERNAME         ${DISCORD_USERNAME}" || echo "  DISCORD_USERNAME         not set (default: amit-ai-team)"
    [ -n "${DISCORD_AVATAR_URL:-}"      ] && echo "{{g}}✓{{n}} DISCORD_AVATAR_URL       set" || echo "  DISCORD_AVATAR_URL       not set (Discord default)"
