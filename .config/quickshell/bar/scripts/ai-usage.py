#!/usr/bin/env python3
"""Token usage and plan limits for Claude and ChatGPT (Codex), as JSON for AiUsagePanel.

Claude: limits from the OAuth usage endpoint (same as /usage in Claude Code, with the
token Claude Code keeps in ~/.claude/.credentials.json); daily tokens from the
transcripts in ~/.claude/projects.
ChatGPT: limits and daily tokens from the Codex session logs in ~/.codex/sessions.
Limits there are as of the last Codex request.

Daily tokens count everything billed per request: input, output, cache writes and reads.
Days are local, oldest first, today last.
"""
import datetime as dt
import json
import os
import urllib.request
from pathlib import Path

HOME = Path.home()
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


def claude_limits():
    creds = json.loads((HOME / ".claude/.credentials.json").read_text())
    token = creds["claudeAiOauth"]["accessToken"]
    req = urllib.request.Request(
        "https://api.anthropic.com/api/oauth/usage",
        headers={"Authorization": f"Bearer {token}", "anthropic-beta": "oauth-2025-04-20"},
    )
    with urllib.request.urlopen(req, timeout=10) as r:
        data = json.load(r)
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


def claude_days():
    days = empty_days()
    seen = set()
    for path in recent_files(HOME / ".claude/projects", "*.jsonl"):
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


try:
    codex_limits, codex_days = codex()
    chatgpt = {"limits": codex_limits, "days": day_list(codex_days), "error": None}
    if not (HOME / ".codex/sessions").is_dir():
        chatgpt["error"] = "No Codex sessions yet"
except Exception as e:
    chatgpt = {"limits": [], "days": day_list(empty_days()), "error": f"Codex logs unreadable: {e}"}

print(json.dumps({
    "updated": now.isoformat(),
    "claude": section(claude_limits, claude_days),
    "chatgpt": chatgpt,
}))
