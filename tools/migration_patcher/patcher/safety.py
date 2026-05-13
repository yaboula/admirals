from __future__ import annotations

import re
from pathlib import Path

MARKER = '-- SONAR_PATCHED v1'
REAL_SERVER_ROOT = Path('D:/FiveM_Server/Sonar').resolve()
MINOR_HINT_RE = re.compile(r'(^|[_\W])(minor|cents|centavos)|(_minor|_cents|_centavos|Minor|Cents)\b', re.IGNORECASE)


def contains_marker(text: str) -> bool:
    return MARKER in text


def is_qb_core_resource(path: Path) -> bool:
    return path.name.lower() == 'qb-core'


def is_real_server_path(path: Path) -> bool:
    try:
        resolved = path.resolve()
    except OSError:
        resolved = path.absolute()
    return resolved == REAL_SERVER_ROOT or REAL_SERVER_ROOT in resolved.parents


def has_minor_unit_hint(expr: str) -> bool:
    return MINOR_HINT_RE.search(expr or '') is not None


def is_float_literal(expr: str) -> bool:
    return re.fullmatch(r'\s*\d+\.\d+\s*', expr or '') is not None


def is_integer_literal(expr: str) -> bool:
    return re.fullmatch(r'\s*\d+\s*', expr or '') is not None


def to_minor_expr(expr: str) -> str:
    raw = (expr or '').strip()
    if is_integer_literal(raw):
        return str(int(raw) * 100)
    floor_match = re.fullmatch(r'math\.floor\s*\((.*)\)', raw)
    if floor_match:
        inner = floor_match.group(1).strip()
        return f'math.floor(({inner}) * 100)'
    return f'({raw}) * 100'


def make_marker(pattern_id: str, original_line: int) -> str:
    return f'{MARKER}: {pattern_id} orig_line={original_line}'
