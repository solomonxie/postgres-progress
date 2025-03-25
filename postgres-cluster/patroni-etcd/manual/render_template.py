"""
HOW TO USE:
    $ python render_template.py roles.sql pg_passwords.env
"""

import re
import sys
from pathlib import Path
from jinja2 import Template


def load_env(path: str) -> dict:
    pairs = {}
    p = Path(path)
    if not p.exists():
        return {}
    ptn = re.compile(r'[\'"]?([^\s#\'"]+)[\'"]?')
    lines = p.read_text().split('\n')
    for s in lines:
        if '=' not in s:
            continue
        s = s.strip()
        key = s[:s.index('=')]
        value = s[s.index('=')+1:]
        result = ptn.findall(value)
        value = result[0] if result else ''
        ignores = [
            key.startswith('#') or value.startswith('#'),
            key in [None, ''] or value in [None, ''],
            '-' in key,
            bool(re.search(r'^[0-9]', key)),
            value.startswith('"') and not value.endswith('"'),
            value.startswith("'") and not value.endswith("'"),
            # bool(value),  # Value is always a string
        ]
        if any(ignores):
            print(f'IGNORE ENV-V [{key}] FOR CHECKS: {ignores}')
            continue
        pairs[key] = value
    print(f'OK: LOADED ENV VARS FROM [{path}]: {list(pairs.keys())}')
    return pairs


if __name__ == '__main__':
    _, temlate_path, envfile_path = sys.argv
    with open(temlate_path) as f:
        template = Template(f.read())
    variables = load_env(envfile_path)
    rendered = template.render(**variables)
    print(rendered)
