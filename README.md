# amit-claude

Personal AI agent skills and rules for Cursor and Claude CLI.

## Quickstart

```bash
# 1. Clone and set up symlinks (once per machine)
cd ~/src/amit-claude
just setup

# 2. Add the ai alias to ~/.zshrc so targets work from any directory
echo "alias ai='just -f ~/src/amit-claude/justfile'" >> ~/.zshrc
source ~/.zshrc

# 3. New project — initialize memory + task tracking (run from the project dir)
cd /path/to/project
ai memory-init

# 4. Discord notifications (optional)
cp ~/src/amit-claude/config/discord.env.example ~/src/amit-claude/config/discord.env
# fill in your webhook URL, then:
ai notify "AI team online"
```

## Team

14 specialists — see `CLAUDE.md` for the full list and activation triggers. Start with `qa-team-orchestrator` for any broad request.

## Usage

**Cursor** — skills and rules are live via symlink. Just prompt:
> "Use the QA team orchestrator to plan testing for the checkout feature."
> "Act as the security test engineer and review this auth flow."

**Claude CLI** — `~/.claude/CLAUDE.md` is a symlink to this repo. Team is always loaded:
```bash
claude "As the devops engineer, write a GitHub Actions pipeline for this service."
```

## justfile targets

All targets are available from any directory via the `ai` alias.

```bash
ai setup              # first-time machine setup (symlinks)
ai status             # verify symlinks
ai memory-init        # init memory/ + bd in current directory
ai memory-status      # show project memory status
ai tasks              # unblocked bd tasks
ai task "Title" [0-3] # create a task
ai claim <id>         # claim a task
ai done <id>          # mark complete
ai notify "msg"       # Discord notification
ai alert "msg"        # Discord alert
ai discord-status     # check Discord config
```

## Structure

```
.cursor/
├── skills/   # agent skills (symlinked to ~/.cursor/skills)
└── rules/    # always-on coding rules (symlinked to ~/.cursor/rules)
CLAUDE.md     # Claude CLI global config (symlinked to ~/.claude/CLAUDE.md)
config/
└── discord.env.example
justfile
```
