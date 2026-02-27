#!/usr/bin/env python3
import os, sys, json
from pathlib import Path
import argparse
import httpx
from loguru import logger
from rich.logging import RichHandler
from rich.table import Table
from rich import print as rich_print

# Configure loguru with rich handler
logger.remove()  # Remove default handler
logger.add(
    RichHandler(rich_tracebacks=True, show_time=True, show_level=True, show_path=True),
    format="{message}",
    level="INFO"
)

cfg_path = Path("config/discord.env")
API  = "https://discord.com/api/v10"
HDR: dict[str, str] = {}


def get_credentials(token_arg = str, guild_arg = str) -> tuple[str, str]:
    token = os.environ.get("DISCORD_BOT_TOKEN") or token_arg
    guild = os.environ.get("DISCORD_GUILD_ID") or guild_arg
    logger.debug(f"Credentials from env/args: token_present={bool(token)}, guild={guild}")
    if not token or not guild:
        logger.error("✗ Missing credentials")
        logger.info("\nUsage:")
        logger.info("  DISCORD_BOT_TOKEN=xxx DISCORD_GUILD_ID=yyy just discord-setup")
        logger.info("Bot token → discord.com/developers/applications → your app → Bot → Reset Token")
        logger.info("Guild ID  → Discord: right-click server → Copy Server ID (Developer Mode)")
        sys.exit(1)
    logger.debug(f"Config loaded: token_present={bool(token)}, guild={guild}, config_file={cfg_path}")
    HDR.update({"Authorization": f"Bot {token}", "Content-Type": "application/json"})
    return token, guild



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


def setup(token_arg: str | None = None, guild_arg: str | None = None) -> None:
    # initialize credentials and headers
    token, guild = get_credentials(token_arg, guild_arg)

    logger.info("Validating token and retrieving bot identity")
    me = api("GET", "/users/@me")
    client_id = me["id"]
    logger.info(f"✓ Bot authenticated: {me['username']} (id: {client_id})")

    # List guilds to verify
    logger.info("Fetching guilds bot is currently in")
    bot_guilds = api("GET", "/users/@me/guilds")
    logger.info(f"Found {len(bot_guilds)} guild(s)")

    for g in bot_guilds:
        marker = " ← MATCH" if g["id"] == guild else ""
        logger.info(f"  {g['id']}  {g['name']}{marker}")
    if not any(g["id"] == guild for g in bot_guilds):
        logger.error(f"✗ Guild ID {guild} not found in bot's guild list above.")
        logger.error("Either the bot wasn't fully added, or the Guild ID is wrong.")
        sys.exit(1)
    logger.debug(f"Guild ID {guild} verified")

    logger.info(f"Fetching channels for guild {guild}")
    channels_data = api("GET", f"/guilds/{guild}/channels")
    logger.debug(f"Retrieved {len(channels_data)} channel(s)")
    all_channels = {c["name"]: c["id"] for c in channels_data if c["type"] == 0}
    logger.debug(f"Filtered to {len(all_channels)} text channel(s)")

    results: dict[str, str] = {}
    for name, var in CHANNELS.items():
        if name not in all_channels:
            logger.warning(f"  ⚠  #{name} not found — skipping {var}")
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
            logger.info(f"  ↻  #{name} (existing webhook)")
        else:
            logger.debug(f"Creating new webhook for #{name}")
            wh = api("POST", f"/channels/{channel_id}/webhooks", {"name": "Bot"})
            url = f"https://discord.com/api/webhooks/{wh['id']}/{wh['token']}"
            results[var] = url
            logger.info(f"  ✓  #{name} (new webhook)")

    lines = [
        "# Discord Webhook Configuration — generated by just discord-setup",
        "# DO NOT COMMIT — this file is gitignored.",
        "",
        'DISCORD_USERNAME="Bot"',
        "DISCORD_AVATAR_URL=",
        "",
    ]
    # append entries grouped by category comments
    lines.append("# Webhooks")
    for channel_var in CHANNELS.values():
        lines.append(f"{channel_var}={results.get(channel_var, '')}")
    lines.append("")
    lines.append("# Process")
    for channel_var in ("DISCORD_WEBHOOK_DECISIONS","DISCORD_WEBHOOK_CICD"):
        lines.append(f"{channel_var}={results.get(channel_var, '')}")
    # note: process channels are included above via channels.values() as well, duplicates ok

    logger.info(f"Writing configuration to {cfg_path}")
    cfg_path.write_text("\n".join(lines) + "\n")

    # Count new vs existing webhooks
    total_webhooks = sum(1 for v in results.values() if v)
    logger.info(f"\n✓ Configuration saved {cfg_path}")
    logger.info(f"Summary: {total_webhooks} webhook(s) configured")
    logger.info("Next step: Run 'just discord-status' to verify")


def status() -> None:
    if not cfg_path.exists():
        logger.warning(f" Discord not configured — {cfg_path} missing")
        sys.exit(0)
    env = {}
    for line in cfg_path.read_text().splitlines():
        if "=" in line and not line.startswith("#"):
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip().strip('"')
    table = Table(title=f"Discord config ({cfg_path})")
    table.add_column("Variable")
    table.add_column("Value", overflow="fold")
    for key in list(CHANNELS.values()) + ["DISCORD_USERNAME"]:
        val = env.get(key, "(not set)")
        table.add_row(key, val)
    rich_print(table)


def main() -> None:
    parser = argparse.ArgumentParser(description="Discord webhook helper")
    sub = parser.add_subparsers(dest="cmd")
    sp = sub.add_parser("setup")
    sp.add_argument("--token", help="Discord bot token")
    sp.add_argument("--guild", help="Guild ID")
    sub.add_parser("status")
    args = parser.parse_args()
    if args.cmd == "setup":
        setup(token_arg=getattr(args, "token", None), guild_arg=getattr(args, "guild", None))
    elif args.cmd == "status":
        status()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()

