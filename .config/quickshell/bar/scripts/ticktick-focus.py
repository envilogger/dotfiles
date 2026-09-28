#!/usr/bin/env python3
"""Read TickTick's current Pomodoro using its local session; emit public JSON only."""
import datetime
import json
import math
import os
from pathlib import Path
import time
import urllib.error
import urllib.request


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


def timestamp(value):
    parsed = datetime.datetime.fromisoformat(value.replace('Z', '+00:00'))
    if parsed.tzinfo is None:
        raise ValueError('missing timezone')
    return parsed.timestamp()


def normalize(current, now):
    result = {'state': 'idle', 'remaining': 0, 'observed': now}
    if not current:
        return result
    if not isinstance(current, dict):
        raise ValueError('invalid current focus')
    if current.get('type') != 0 or current.get('status') not in (0, 1) or current.get('exited'):
        return result
    start = timestamp(current['startTime'])
    duration = float(current['duration']) * 60
    if not math.isfinite(duration) or duration <= 0 or start > now + 5:
        raise ValueError('invalid duration or start')
    paused_at = None
    paused_total = 0
    for log in sorted(current.get('pauseLogs') or [], key=lambda item: timestamp(item['time'])):
        when = min(now, timestamp(log['time']))
        if when < start:
            continue
        if log['type'] == 0:
            if paused_at is None:
                paused_at = when
        elif paused_at is not None:
            paused_total += max(0, when - paused_at)
            paused_at = None
    paused = current['status'] == 1
    if paused != (paused_at is not None):
        raise ValueError('incomplete pause history')
    elapsed = max(0, (paused_at if paused else now) - start - paused_total)
    remaining = max(0, duration - elapsed)
    if remaining > 0:
        result.update(state='paused' if paused else 'running', remaining=remaining)
    return result


def probe():
    try:
        config = Path(os.environ.get('XDG_CONFIG_HOME') or Path.home() / '.config') / 'ticktick/config.json'
        token = json.loads(config.read_text()).get('token')
        if not isinstance(token, str) or not token or any(c in token for c in '\r\n;'):
            return {'state': 'unavailable', 'error': 'no_session'}
        request = urllib.request.Request(
            'https://ms.ticktick.com/focus/batch/focusOp',
            data=b'{"lastPoint":0,"opList":[]}',
            headers={'Cookie': 't=' + token, 'Content-Type': 'application/json', 'Accept': 'application/json'},
        )
        with urllib.request.build_opener(NoRedirect()).open(request, timeout=8) as response:
            data = json.loads(response.read(2_000_001))
        if not isinstance(data, dict) or 'errorCode' in data or 'current' not in data:
            raise ValueError('invalid response')
        return normalize(data['current'], time.time())
    except FileNotFoundError:
        return {'state': 'unavailable', 'error': 'no_session'}
    except urllib.error.HTTPError as error:
        return {'state': 'unavailable', 'error': 'http_' + str(error.code)}
    except (OSError, ValueError, TypeError, KeyError, AttributeError):
        # Never log exceptions or response bodies: they may contain session or task data.
        return {'state': 'unavailable', 'error': 'sync_failed'}


if __name__ == '__main__':
    print(json.dumps(probe(), allow_nan=False))
