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
# Channel routing: each target picks a specific webhook; falls back to UPDATES if unset.
# All targets are no-ops if config/discord.env does not exist.

# General update — #updates channel
notify msg:
    #!/usr/bin/env bash
    set -euo pipefail
    cfg="{{discord_config}}"
    [ ! -f "$cfg" ] && echo "{{y}}⚠{{n}} Discord not configured — copy config/discord.env.example → config/discord.env" && exit 0
    source "$cfg"
    url="${DISCORD_WEBHOOK_UPDATES:-}"
    [ -z "$url" ] && echo "{{y}}⚠{{n}} DISCORD_WEBHOOK_UPDATES not set" && exit 0
    payload=$(jq -n --arg c "{{msg}}" --arg u "${DISCORD_USERNAME:-amit-ai-team}" --arg a "${DISCORD_AVATAR_URL:-}" \
        '{content:$c,username:$u}+(if $a!="" then {avatar_url:$a} else {} end)')
    curl -s -o /dev/null -w "%{http_code}" -X POST "$url" -H "Content-Type: application/json" -d "$payload" \
        | grep -q "^2" && echo "{{g}}✓{{n}} Discord notification sent" || echo "{{r}}✗{{n}} Discord POST failed"

# Alert — #alerts channel (falls back to #updates)
alert msg:
    #!/usr/bin/env bash
    set -euo pipefail
    cfg="{{discord_config}}"
    [ ! -f "$cfg" ] && echo "{{y}}⚠{{n}} Discord not configured" && exit 0
    source "$cfg"
    url="${DISCORD_WEBHOOK_ALERTS:-${DISCORD_WEBHOOK_UPDATES:-}}"
    [ -z "$url" ] && echo "{{y}}⚠{{n}} No alert webhook set" && exit 0
    payload=$(jq -n --arg c ":warning: {{msg}}" --arg u "${DISCORD_USERNAME:-amit-ai-team}" --arg a "${DISCORD_AVATAR_URL:-}" \
        '{content:$c,username:$u}+(if $a!="" then {avatar_url:$a} else {} end)')
    curl -s -o /dev/null -w "%{http_code}" -X POST "$url" -H "Content-Type: application/json" -d "$payload" \
        | grep -q "^2" && echo "{{g}}✓{{n}} Discord alert sent" || echo "{{r}}✗{{n}} Discord POST failed"

# Specialist channel shortcuts — fall back to #updates if channel webhook not set
# Usage: just notify-pm "PRD v2 approved"  |  just notify-security "XSS in /login"
notify-pm msg:
    just _notify-channel DISCORD_WEBHOOK_PM ":clipboard: [PM] {{msg}}"
notify-design msg:
    just _notify-channel DISCORD_WEBHOOK_DESIGN ":art: [Design] {{msg}}"
notify-exploration msg:
    just _notify-channel DISCORD_WEBHOOK_EXPLORATION ":mag: [Explorer] {{msg}}"
notify-engineering msg:
    just _notify-channel DISCORD_WEBHOOK_ENGINEERING ":gear: [Engineering] {{msg}}"
notify-qa-strategy msg:
    just _notify-channel DISCORD_WEBHOOK_QA_STRATEGY ":white_check_mark: [QA Strategy] {{msg}}"
notify-qa msg:
    just _notify-channel DISCORD_WEBHOOK_QA_IMPLEMENTATION ":test_tube: [QA] {{msg}}"
notify-security msg:
    just _notify-channel DISCORD_WEBHOOK_SECURITY ":shield: [Security] {{msg}}"
notify-performance msg:
    just _notify-channel DISCORD_WEBHOOK_PERFORMANCE ":racing_car: [Perf] {{msg}}"
notify-decision msg:
    just _notify-channel DISCORD_WEBHOOK_DECISIONS ":brain: [Decision] {{msg}}"
notify-cicd msg:
    just _notify-channel DISCORD_WEBHOOK_CICD ":rocket: [CI/CD] {{msg}}"

# Internal: resolve env var by name (indirect expansion), fall back to UPDATES
_notify-channel varname msg:
    #!/usr/bin/env bash
    set -euo pipefail
    cfg="{{discord_config}}"
    [ ! -f "$cfg" ] && exit 0
    source "$cfg"
    varname="{{varname}}"
    url="${!varname:-}"
    url="${url:-${DISCORD_WEBHOOK_UPDATES:-}}"
    [ -z "$url" ] && exit 0
    payload=$(jq -n --arg c "{{msg}}" --arg u "${DISCORD_USERNAME:-amit-ai-team}" --arg a "${DISCORD_AVATAR_URL:-}" \
        '{content:$c,username:$u}+(if $a!="" then {avatar_url:$a} else {} end)')
    curl -s -o /dev/null -w "%{http_code}" -X POST "$url" -H "Content-Type: application/json" -d "$payload" \
        | grep -q "^2" && echo "{{g}}✓{{n}} sent" || echo "{{r}}✗{{n}} failed"

# Post handoff summary from memory/handoffs.md
# Usage: just notify-handoff [agent] [path]
notify-handoff agent="" path=invocation_directory():
    #!/usr/bin/env bash
    set -euo pipefail
    handoffs="{{path}}/memory/handoffs.md"
    if [ ! -f "$handoffs" ]; then
        echo "{{r}}✗{{n}} No memory/handoffs.md at {{path}} — run: just memory-init {{path}}"
        exit 1
    fi
    if [ -n "{{agent}}" ]; then
        msg=$(awk '/^## {{agent}}/{found=1} found && /^## / && !/^## {{agent}}/{exit} found{print}' "$handoffs" | head -30)
    else
        msg=$(tail -20 "$handoffs")
    fi
    [ -z "$msg" ] && echo "{{y}}⚠{{n}} No handoff content found for '{{agent}}'" && exit 0
    just notify "$msg"

# Post task completion to Discord
# Usage: just notify-done <task-id>
notify-done id:
    #!/usr/bin/env bash
    set -euo pipefail
    command -v bd &>/dev/null || { echo "{{y}}⚠{{n}} bd not found"; exit 0; }
    info=$(bd show {{id}} --json 2>/dev/null | jq -r '"Task done: [" + .id + "] " + .title + " (P" + (.priority|tostring) + ")"' 2>/dev/null || echo "Task {{id}} marked done")
    just notify "$info"

# Create webhooks for all channels via Discord API and write config/discord.env
# Prerequisites: Discord bot with "Manage Webhooks" permission in your server
#
# Usage:
#   DISCORD_BOT_TOKEN=... DISCORD_GUILD_ID=... just discord-setup
#   just discord-setup token=Bot_TOKEN guild=GUILD_ID
#
# How to get these:
#   Bot token  → discord.com/developers/applications → your app → Bot → Reset Token
#   Guild ID   → Discord: right-click your server → Copy Server ID (enable Developer Mode first)
discord-setup token="" guild="":
    #!/usr/bin/env bash
    set -euo pipefail

    TOKEN="${token:-${DISCORD_BOT_TOKEN:-}}"
    GUILD="${guild:-${DISCORD_GUILD_ID:-}}"

    if [ -z "$TOKEN" ] || [ -z "$GUILD" ]; then
        echo "{{r}}✗{{n}} Missing credentials."
        echo ""
        echo "Usage:"
        echo "  DISCORD_BOT_TOKEN=xxx DISCORD_GUILD_ID=yyy just discord-setup"
        echo "  just discord-setup token=xxx guild=yyy"
        echo ""
        echo "Bot token  → discord.com/developers/applications → your app → Bot → Reset Token"
        echo "Guild ID   → Discord: right-click server → Copy Server ID (enable Developer Mode)"
        exit 1
    fi

    API="https://discord.com/api/v10"
    HDR="Authorization: Bot $TOKEN"

    # Verify bot access
    echo "Fetching channels for guild $GUILD ..."
    channels=$(curl -sf -H "$HDR" "$API/guilds/$GUILD/channels" 2>&1) || {
        echo "{{r}}✗{{n}} API call failed — check your token and guild ID"
        exit 1
    }

    # Channel name → env var mapping
    declare -A MAPPING=(
        ["updates"]="DISCORD_WEBHOOK_UPDATES"
        ["alerts"]="DISCORD_WEBHOOK_ALERTS"
        ["pm"]="DISCORD_WEBHOOK_PM"
        ["design"]="DISCORD_WEBHOOK_DESIGN"
        ["exploration"]="DISCORD_WEBHOOK_EXPLORATION"
        ["engineering"]="DISCORD_WEBHOOK_ENGINEERING"
        ["qa-strategy"]="DISCORD_WEBHOOK_QA_STRATEGY"
        ["qa-implementation"]="DISCORD_WEBHOOK_QA_IMPLEMENTATION"
        ["security"]="DISCORD_WEBHOOK_SECURITY"
        ["performance"]="DISCORD_WEBHOOK_PERFORMANCE"
        ["decisions"]="DISCORD_WEBHOOK_DECISIONS"
        ["cicd"]="DISCORD_WEBHOOK_CICD"
    )

    declare -A RESULTS

    for channel_name in "${!MAPPING[@]}"; do
        var="${MAPPING[$channel_name]}"

        # Find channel ID by name (type 0 = text channel)
        channel_id=$(echo "$channels" | jq -r --arg name "$channel_name" \
            '.[] | select(.type == 0 and .name == $name) | .id' | head -1)

        if [ -z "$channel_id" ]; then
            echo "{{y}}⚠{{n}}  channel #$channel_name not found — skipping $var"
            RESULTS[$var]=""
            continue
        fi

        # Create webhook
        response=$(curl -sf -X POST -H "$HDR" -H "Content-Type: application/json" \
            -d "{\"name\":\"amit-ai-team\"}" \
            "$API/channels/$channel_id/webhooks" 2>&1) || {
            echo "{{r}}✗{{n}}  failed to create webhook for #$channel_name"
            RESULTS[$var]=""
            continue
        }

        url=$(echo "$response" | jq -r '"https://discord.com/api/webhooks/" + .id + "/" + .token')
        RESULTS[$var]="$url"
        echo "{{g}}✓{{n}}  #$channel_name → $var"
    done

    # Write config/discord.env
    cfg="{{discord_config}}"
    {
        printf '# Discord Webhook Configuration — generated by just discord-setup\n'
        printf '# DO NOT COMMIT — this file is gitignored.\n\n'
        printf 'DISCORD_USERNAME="amit-ai-team"\n'
        printf 'DISCORD_AVATAR_URL=\n\n'
        printf '# Activity\n'
        printf 'DISCORD_WEBHOOK_UPDATES=%s\n'         "${RESULTS[DISCORD_WEBHOOK_UPDATES]}"
        printf 'DISCORD_WEBHOOK_ALERTS=%s\n\n'        "${RESULTS[DISCORD_WEBHOOK_ALERTS]}"
        printf '# Specialist\n'
        printf 'DISCORD_WEBHOOK_PM=%s\n'              "${RESULTS[DISCORD_WEBHOOK_PM]}"
        printf 'DISCORD_WEBHOOK_DESIGN=%s\n'          "${RESULTS[DISCORD_WEBHOOK_DESIGN]}"
        printf 'DISCORD_WEBHOOK_EXPLORATION=%s\n'     "${RESULTS[DISCORD_WEBHOOK_EXPLORATION]}"
        printf 'DISCORD_WEBHOOK_ENGINEERING=%s\n'     "${RESULTS[DISCORD_WEBHOOK_ENGINEERING]}"
        printf 'DISCORD_WEBHOOK_QA_STRATEGY=%s\n'     "${RESULTS[DISCORD_WEBHOOK_QA_STRATEGY]}"
        printf 'DISCORD_WEBHOOK_QA_IMPLEMENTATION=%s\n' "${RESULTS[DISCORD_WEBHOOK_QA_IMPLEMENTATION]}"
        printf 'DISCORD_WEBHOOK_SECURITY=%s\n'        "${RESULTS[DISCORD_WEBHOOK_SECURITY]}"
        printf 'DISCORD_WEBHOOK_PERFORMANCE=%s\n\n'   "${RESULTS[DISCORD_WEBHOOK_PERFORMANCE]}"
        printf '# Process\n'
        printf 'DISCORD_WEBHOOK_DECISIONS=%s\n'       "${RESULTS[DISCORD_WEBHOOK_DECISIONS]}"
        printf 'DISCORD_WEBHOOK_CICD=%s\n'            "${RESULTS[DISCORD_WEBHOOK_CICD]}"
    } > "$cfg"

    echo ""
    echo "{{g}}Done.{{n}} Written to $cfg"
    echo "Run 'just discord-status' to verify."

# Show Discord config status
discord-status:
    #!/usr/bin/env bash
    cfg="{{discord_config}}"
    if [ ! -f "$cfg" ]; then
        echo "{{r}}✗{{n}} config/discord.env not found"
        echo "  Setup: cp config/discord.env.example config/discord.env"
        exit 0
    fi
    source "$cfg"
    echo "=== Discord ($cfg) ==="
    check() { [ -n "${!1:-}" ] && echo "{{g}}✓{{n}} $1" || echo "  $1  (not set)"; }
    check DISCORD_WEBHOOK_UPDATES
    check DISCORD_WEBHOOK_ALERTS
    check DISCORD_WEBHOOK_PM
    check DISCORD_WEBHOOK_DESIGN
    check DISCORD_WEBHOOK_EXPLORATION
    check DISCORD_WEBHOOK_ENGINEERING
    check DISCORD_WEBHOOK_QA_STRATEGY
    check DISCORD_WEBHOOK_QA_IMPLEMENTATION
    check DISCORD_WEBHOOK_SECURITY
    check DISCORD_WEBHOOK_PERFORMANCE
    check DISCORD_WEBHOOK_DECISIONS
    check DISCORD_WEBHOOK_CICD
    echo ""
    [ -n "${DISCORD_USERNAME:-}" ] && echo "{{g}}✓{{n}} DISCORD_USERNAME  ${DISCORD_USERNAME}" || echo "  DISCORD_USERNAME  not set (default: amit-ai-team)"
