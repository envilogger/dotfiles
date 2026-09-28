#!/usr/bin/env python3
"""Token usage and plan limits for Claude and ChatGPT (Codex), as JSON for AiUsagePanel.

Claude: one section per Claude Code profile, i.e. per CLAUDE_CONFIG_DIR — personal in
~/.claude, work in ~/.claude-work. Limits from the OAuth usage endpoint (same as /usage
in Claude Code, with the token it keeps in <profile>/.credentials.json); daily tokens
from the transcripts in <profile>/projects.
ChatGPT: limits and daily tokens from the Codex session logs in ~/.codex/sessions.
Limits there are as of the last Codex request.

Daily tokens count everything billed per request: input, output, cache writes and reads.
Days are local, oldest first, today last.

Prints the JSON on stdout; with --write it goes to $XDG_STATE_HOME/quickshell/ai-usage.json
instead, which is what the ai-usage.timer systemd user unit does every 90 s and all the
bar reads. Only this script may poll the usage endpoint: it rate-limits hard (HTTP 429),
so running it by hand while the service runs is enough to trip it.
"""
import datetime as dt
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

HOME = Path.home()
CLAUDE_PROFILES = {"claude": HOME / ".claude", "claudeWork": HOME / ".claude-work"}
STATE = Path(os.environ.get("XDG_STATE_HOME") or HOME / ".local/state") / "quickshell"
CACHE = STATE / "ai-usage.json"
DAYS = 7
now = dt.datetime.now().astimezone()
first_day = now.date() - dt.timedelta(days=DAYS - 1)
since = dt.datetime.combine(first_day, dt.time(), now.tzinfo).timestamp()


def parse_time(s):
    return dt.datetime.fromisoformat(s.replace("Z", "+00:00"))


def empty_days():
    return {first_day + dt.timedelta(days=i): 0 for i in range(DAYS)}


def day_list(days):
    return [{"date": d.isoformat(), "tokens": t} for d, t in sorted(days.items())]


def recent_files(root, pattern):
    # Transcripts written to before the window can't hold messages inside it.
    if not root.is_dir():
        return []
    return [p for p in root.rglob(pattern) if p.stat().st_mtime >= since]


def get_json(req):
    """GET some JSON, waiting out one 429: the usage endpoint rate-limits for ~27 s."""
    for attempt in (0, 1):
        try:
            with urllib.request.urlopen(req, timeout=10) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code != 429 or attempt:
                raise
            retry_after = e.headers.get("retry-after")
            print(f"429 from {req.full_url}, retry-after: {retry_after}", file=sys.stderr)
            try:
                wait = int(retry_after)
            except (TypeError, ValueError):
                wait = 0
            # It answers 429 with retry-after 0 as well, so never wait less than the
            # window it actually enforces.
            time.sleep(min(max(wait, 28), 40))


def claude_limits(config_dir):
    creds_path = config_dir / ".credentials.json"
    if not creds_path.is_file():
        raise FileNotFoundError(f"no Claude Code login in {config_dir}")
    creds = json.loads(creds_path.read_text())
    token = creds["claudeAiOauth"]["accessToken"]
    req = urllib.request.Request(
        "https://api.anthropic.com/api/oauth/usage",
        headers={"Authorization": f"Bearer {token}", "anthropic-beta": "oauth-2025-04-20"},
    )
    data = get_json(req)
    limits = []
    for l in data.get("limits") or []:
        model = ((l.get("scope") or {}).get("model") or {}).get("display_name")
        label = {"session": "Session", "weekly": "Week"}.get(l.get("group"), l.get("kind", "?"))
        limits.append({
            "label": f"{label} · {model}" if model else label,
            "percent": l.get("percent") or 0,
            "resetsAt": l.get("resets_at"),
        })
    return limits


def claude_days(config_dir):
    days = empty_days()
    seen = set()
    for path in recent_files(config_dir / "projects", "*.jsonl"):
        with open(path, errors="replace") as f:
            for line in f:
                if '"usage"' not in line:
                    continue
                try:
                    e = json.loads(line)
                    msg = e["message"]
                    u = msg["usage"]
                except (ValueError, KeyError, TypeError):
                    continue
                # A response is logged once per content block, with the same usage.
                key = (msg.get("id"), e.get("requestId"))
                if key in seen:
                    continue
                seen.add(key)
                day = parse_time(e["timestamp"]).astimezone().date()
                if day in days:
                    days[day] += sum(u.get(k) or 0 for k in (
                        "input_tokens", "output_tokens",
                        "cache_creation_input_tokens", "cache_read_input_tokens"))
    return days


def codex():
    days = empty_days()
    latest = None  # (time, rate_limits)
    for path in recent_files(HOME / ".codex/sessions", "rollout-*.jsonl"):
        total = 0
        with open(path, errors="replace") as f:
            for line in f:
                if '"token_count"' not in line:
                    continue
                try:
                    e = json.loads(line)
                    p = e["payload"]
                    if p.get("type") != "token_count":
                        continue
                    t = parse_time(e["timestamp"])
                except (ValueError, KeyError, TypeError):
                    continue
                # total_token_usage is cumulative per session; count the growth.
                usage = ((p.get("info") or {}).get("total_token_usage") or {}).get("total_tokens")
                if usage is not None:
                    day = t.astimezone().date()
                    if day in days:
                        days[day] += max(0, usage - total)
                    total = usage
                if p.get("rate_limits") and (latest is None or t > latest[0]):
                    latest = (t, p["rate_limits"])

    limits = []
    if latest:
        t, rl = latest
        for key in ("primary", "secondary"):
            w = rl.get(key)
            if not w:
                continue
            minutes = w.get("window_minutes") or 0
            label = "Session" if minutes <= 24 * 60 else "Week"
            if w.get("resets_at"):
                resets = dt.datetime.fromtimestamp(w["resets_at"], dt.timezone.utc)
            elif w.get("resets_in_seconds") is not None:
                resets = t + dt.timedelta(seconds=w["resets_in_seconds"])
            else:
                resets = None
            # The window reset since the last request: nothing used in it yet.
            expired = resets is not None and resets <= now
            limits.append({
                "label": label,
                "percent": 0 if expired else w.get("used_percent") or 0,
                "resetsAt": None if expired else resets and resets.isoformat(),
            })
    return limits, days


def section(limits_fn, days_fn):
    out = {"limits": [], "days": [], "error": None}
    try:
        out["limits"] = limits_fn()
    except Exception as e:
        out["error"] = f"Limits unavailable: {e}"
    try:
        out["days"] = day_list(days_fn())
    except Exception as e:
        out["error"] = out["error"] or f"Token stats unavailable: {e}"
    return out


def claude(config_dir, prev_limits=None):
    """One Claude profile. With prev_limits the usage endpoint is left alone and those
    limits are reused: it isn't this profile's turn."""
    limits_fn = (lambda: prev_limits) if prev_limits is not None else (
        lambda: claude_limits(config_dir))
    return section(limits_fn, lambda: claude_days(config_dir))


def collect(fetch=None, prev=None):
    """All of it. fetch names the Claude profiles to ask the usage endpoint about; by
    default every one of them, and the rest reuse their limits from prev."""
    try:
        codex_limits, codex_days = codex()
        chatgpt = {"limits": codex_limits, "days": day_list(codex_days), "error": None}
        if not (HOME / ".codex/sessions").is_dir():
            chatgpt["error"] = "No Codex sessions yet"
    except Exception as e:
        chatgpt = {"limits": [], "days": day_list(empty_days()),
                   "error": f"Codex logs unreadable: {e}"}

    data = {"updated": now.isoformat()}
    for key, config_dir in CLAUDE_PROFILES.items():
        reuse = None if fetch is None or key in fetch else (
            ((prev or {}).get(key) or {}).get("limits") or [])
        data[key] = claude(config_dir, reuse)
    data["chatgpt"] = chatgpt
    return data


def keep_last_known(data, prev):
    """Carry over the limits of the previous run when this one couldn't fetch them."""
    for key, section_ in data.items():
        if not isinstance(section_, dict):
            continue
        old = ((prev.get(key) or {}) if isinstance(prev, dict) else {}).get("limits") or []
        if section_.get("error") and not section_["limits"] and old:
            section_["limits"] = old
            section_["error"] += " (showing last known)"


def write_cache():
    try:
        prev = json.loads(CACHE.read_text())
    except (OSError, ValueError):
        prev = {}
    # One profile per run: the endpoint allows about one call per 27 s per account (and
    # every running Claude Code session polls it too), so asking about both profiles in
    # the same run gets the second one a 429. Limits per profile are thus 3 min old at
    # worst; the daily token stats come from local files and are refreshed every run.
    order = list(CLAUDE_PROFILES)
    if prev:
        last = prev.get("limitsFetched")
        turn = order[(order.index(last) + 1) % len(order)] if last in order else order[0]
        fetch = {turn}
    else:
        # Nothing cached yet: fill every profile, even at the risk of a 429 on the second.
        turn, fetch = order[-1], set(order)
    data = collect(fetch, prev)
    data["limitsFetched"] = turn
    keep_last_known(data, prev)
    STATE.mkdir(parents=True, exist_ok=True)
    # Written aside and renamed, so the bar never reads a half-written file.
    tmp = CACHE.with_name(CACHE.name + ".new")
    tmp.write_text(json.dumps(data))
    os.replace(tmp, CACHE)


if "--write" in sys.argv[1:]:
    write_cache()
else:
    print(json.dumps(collect()))
