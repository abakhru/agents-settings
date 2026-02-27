#!/usr/bin/env python3
import os, sys, json
from pathlib import Path
import httpx
from loguru import logger
from rich.logging import RichHandler
from rich.console import Console

# Initialize rich console
console = Console()

# Configure loguru with rich handler
logger.remove()  # Remove default handler
logger.add(
    RichHandler(rich_tracebacks=True, show_time=True, show_level=True, show_path=True),
    format="{message}",
    level="INFO"
)

logger.debug("Starting Discord setup script")

token = os.environ.get("DISCORD_BOT_TOKEN", "")
guild = os.environ.get("DISCORD_GUILD_ID", "")
cfg = Path("config/discord.env")
logger.debug(f"Config loaded: token_present={bool(token)}, guild={guild}, config_file={cfg}")

if not token or not guild:
    console.print("[bold red]✗ Missing credentials[/bold red]")
    console.print("\n[bold yellow]Usage:[/bold yellow]")
    console.print("  [cyan]DISCORD_BOT_TOKEN=xxx DISCORD_GUILD_ID=yyy just discord-setup[/cyan]")
    console.print("  [cyan]just discord-setup token=xxx guild=yyy[/cyan]")
    console.print("[bold]Bot token[/bold] → discord.com/developers/applications → your app → Bot → Reset Token")
    console.print("[bold]Guild ID[/bold]  → Discord: right-click server → Copy Server ID (Developer Mode)")
    sys.exit(1)

API  = "https://discord.com/api/v10"
HDR  = {"Authorization": f"Bot {token}", "Content-Type": "application/json"}
logger.debug(f"Discord API base: {API}")

CHANNELS = {
    "updates":           "DISCORD_WEBHOOK_UPDATES",
    "alerts":            "DISCORD_WEBHOOK_ALERTS",
    "pm":                "DISCORD_WEBHOOK_PM",
    "design":            "DISCORD_WEBHOOK_DESIGN",
    "exploration":       "DISCORD_WEBHOOK_EXPLORATION",
    "engineering":       "DISCORD_WEBHOOK_ENGINEERING",
    "qa-strategy":       "DISCORD_WEBHOOK_QA_STRATEGY",
    "qa-implementation": "DISCORD_WEBHOOK_QA_IMPLEMENTATION",
    "security":          "DISCORD_WEBHOOK_SECURITY",
    "performance":       "DISCORD_WEBHOOK_PERFORMANCE",
    "decisions":         "DISCORD_WEBHOOK_DECISIONS",
    "cicd":              "DISCORD_WEBHOOK_CICD",
}

def api(method, path, body=None):
    logger.debug(f"API request: {method} {path}")
    if body:
        logger.debug(f"Request body: {json.dumps(body)}")
    
    url = f"{API}{path}"
    try:
        response = httpx.request(method, url, headers=HDR, json=body, timeout=30.0)
        logger.debug(f"API response status: {response.status_code}")
        response.raise_for_status()
        return response.json()
    except httpx.HTTPStatusError as e:
        logger.error(f"HTTP {e.response.status_code} error from Discord")
        try:
            detail = e.response.json()
            code = detail.get("code", "")
            msg  = detail.get("message", str(detail))
            logger.debug(f"Discord error code: {code}, message: {msg}")
        except json.JSONDecodeError:
            code, msg = "", e.response.text[:300]
            logger.debug(f"Failed to parse error response: {msg}")

        logger.error(f"HTTP {e.response.status_code} (Discord code: {code}) — {msg}")

        if e.response.status_code == 401:
            logger.error("Token is invalid. Regenerate at discord.com/developers/applications → Bot → Reset Token")
        elif e.response.status_code == 403 or code in (10004, 1010, 50001):
            logger.error("Bot is not in the server (or missing permissions).")
            logger.error("Open the invite URL printed above in your browser,")
            logger.error("select your server, and click Authorize. Then re-run.")
        elif e.response.status_code == 404:
            logger.error("Wrong Guild ID. Right-click your server in Discord → Copy Server ID.")
        sys.exit(1)
    except json.JSONDecodeError:
        logger.error(f"Discord returned non-JSON for {method} {path}")
        logger.error(f"Raw response: {response.text[:500]}")
        sys.exit(1)

# Validate token and get bot's client ID
logger.info("Validating token and retrieving bot identity")
me = api("GET", "/users/@me")
client_id = me["id"]
console.print(f"[bold green]✓ Bot authenticated:[/bold green] [cyan]{me['username']}[/cyan] (id: [yellow]{client_id}[/yellow])")

# Print invite URL — must be opened in browser to add bot to the server
# logger.debug("Generating bot invitation URL")
# perms = (1 << 10) | (1 << 29)  # VIEW_CHANNEL + MANAGE_WEBHOOKS = 536871936
# logger.debug(f"Permission bits: {perms}")
# invite = f"https://discord.com/oauth2/authorize?client_id={client_id}&scope=bot&permissions={perms}"
# console.print(f"\n[bold magenta]{'─'*60}[/bold magenta]")
# console.print("[bold cyan]STEP:[/bold cyan] [yellow]Open this URL in your browser to add the bot to your server:[/yellow]")
# console.print(f"  [blue]{invite}[/blue]")
# console.print(f"[bold magenta]{'─'*60}[/bold magenta]\n")
# input("Press Enter once the bot is in your server to continue ...")

# List all guilds the bot is in — helps verify guild ID
logger.info("Fetching guilds bot is currently in")
bot_guilds = api("GET", "/users/@me/guilds")
logger.info(f"Found {len(bot_guilds)} guild(s)")

for g in bot_guilds:
    marker = " [bold green]← MATCH[/bold green]" if g["id"] == guild else ""
    console.print(f"  [cyan]{g['id']}[/cyan]  [yellow]{g['name']}[/yellow]{marker}")
if not any(g["id"] == guild for g in bot_guilds):
    console.print(f"[bold red]✗ Guild ID {guild} not found in bot's guild list above.[/bold red]")
    console.print("[red]Either the bot wasn't fully added, or the Guild ID is wrong.[/red]")
    sys.exit(1)
logger.debug(f"Guild ID {guild} verified")

logger.info(f"Fetching channels for guild {guild}")
channels_data = api("GET", f"/guilds/{guild}/channels")
logger.debug(f"Retrieved {len(channels_data)} channel(s)")
all_channels = {c["name"]: c["id"] for c in channels_data if c["type"] == 0}
logger.debug(f"Filtered to {len(all_channels)} text channel(s)")

results = {}
for name, var in CHANNELS.items():
    if name not in all_channels:
        console.print(f"  [yellow]⚠[/yellow]  [cyan]#{name}[/cyan] [red]not found[/red] — skipping [dim]{var}[/dim]")
        results[var] = ""
        continue
    
    channel_id = all_channels[name]
    logger.debug(f"Processing webhook for #{name}")
    
    # Check if webhook already exists
    existing_webhooks = api("GET", f"/channels/{channel_id}/webhooks")
    logger.debug(f"Found {len(existing_webhooks)} existing webhook(s) in #{name}")
    
    existing_wh = None
    for wh in existing_webhooks:
        if wh.get("name") == "Bot":
            existing_wh = wh
            logger.debug(f"Found existing webhook for #{name}")
            break
    
    if existing_wh:
        url = f"https://discord.com/api/webhooks/{existing_wh['id']}/{existing_wh['token']}"
        results[var] = url
        console.print(f"  [bold cyan]↻[/bold cyan]  [cyan]#{name}[/cyan] [dim](existing webhook)[/dim]")
    else:
        logger.debug(f"Creating new webhook for #{name}")
        wh = api("POST", f"/channels/{channel_id}/webhooks", {"name": "Bot"})
        url = f"https://discord.com/api/webhooks/{wh['id']}/{wh['token']}"
        results[var] = url
        console.print(f"  [bold green]✓[/bold green]  [cyan]#{name}[/cyan] [dim](new webhook)[/dim]")

lines = [
    "# Discord Webhook Configuration — generated by just discord-setup",
    "# DO NOT COMMIT — this file is gitignored.",
    "",
    'DISCORD_USERNAME="Bot"',
    "DISCORD_AVATAR_URL=",
    "",
    "# Activity",
    f"DISCORD_WEBHOOK_UPDATES={results['DISCORD_WEBHOOK_UPDATES']}",
    f"DISCORD_WEBHOOK_ALERTS={results['DISCORD_WEBHOOK_ALERTS']}",
    "",
    "# Specialist",
    f"DISCORD_WEBHOOK_PM={results['DISCORD_WEBHOOK_PM']}",
    f"DISCORD_WEBHOOK_DESIGN={results['DISCORD_WEBHOOK_DESIGN']}",
    f"DISCORD_WEBHOOK_EXPLORATION={results['DISCORD_WEBHOOK_EXPLORATION']}",
    f"DISCORD_WEBHOOK_ENGINEERING={results['DISCORD_WEBHOOK_ENGINEERING']}",
    f"DISCORD_WEBHOOK_QA_STRATEGY={results['DISCORD_WEBHOOK_QA_STRATEGY']}",
    f"DISCORD_WEBHOOK_QA_IMPLEMENTATION={results['DISCORD_WEBHOOK_QA_IMPLEMENTATION']}",
    f"DISCORD_WEBHOOK_SECURITY={results['DISCORD_WEBHOOK_SECURITY']}",
    f"DISCORD_WEBHOOK_PERFORMANCE={results['DISCORD_WEBHOOK_PERFORMANCE']}",
    "",
    "# Process",
    f"DISCORD_WEBHOOK_DECISIONS={results['DISCORD_WEBHOOK_DECISIONS']}",
    f"DISCORD_WEBHOOK_CICD={results['DISCORD_WEBHOOK_CICD']}",
]
logger.info(f"Writing configuration to {cfg}")
cfg.write_text("\n".join(lines) + "\n")

# Count new vs existing webhooks
total_webhooks = sum(1 for v in results.values() if v)
console.print(f"\n[bold green]✓ Configuration saved[/bold green] [cyan]{cfg}[/cyan]")
console.print(f"[bold cyan]Summary:[/bold cyan] [green]{total_webhooks}[/green] webhook(s) configured")
console.print("[bold yellow]Next step:[/bold yellow] [cyan]Run 'just discord-status' to verify[/cyan]")
