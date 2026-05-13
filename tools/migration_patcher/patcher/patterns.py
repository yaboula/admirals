from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Iterable


@dataclass(frozen=True)
class PatternSpec:
    pattern_id: str
    severity: str
    description: str
    regex: re.Pattern[str]
    action: str


SAFE_PATTERNS = {
    'S1': 'Online player AddMoney/RemoveMoney bank bare call',
    'S2': 'Online player RemoveMoney bank truthy if-check',
    'S3': 'Offline player AddMoney/RemoveMoney bank by citizenid',
    'S4': 'GetBalance read pattern skipped in Phase A',
}

UNSAFE_PATTERNS: tuple[PatternSpec, ...] = (
    PatternSpec('U1', 'INFO', 'cash/crypto/black_money moneytype is Phase B scope', re.compile(r"\b\w+\.Functions\.(AddMoney|RemoveMoney|SetMoney)\(\s*['\"](cash|crypto|black_money)['\"]\s*,"), 'manual'),
    PatternSpec('U2', 'HIGH', 'SetMoney bank is destructive and requires manual delta migration', re.compile(r"\b\w+\.Functions\.SetMoney\(\s*['\"]bank['\"]\s*,"), 'manual'),
    PatternSpec('U3', 'MEDIUM', 'loop or multi-target binding cannot be resolved to one source', re.compile(r"\bfor\s+[^,\n]+\s*,\s*(\w+)\s+in\s+pairs\s*\([^\n]+\)\s+do[\s\S]*?\1\.Functions\.(Add|Remove|Set)Money"), 'manual'),
    PatternSpec('U4', 'CRITICAL', 'direct PlayerData bank mutation bypasses QBCore and SONAR audit', re.compile(r"\b\w+\.PlayerData\.money(?:\.bank|\[['\"]bank['\"]\])\s*="), 'manual'),
    PatternSpec('U5', 'CRITICAL', 'raw SQL money mutation bypasses both layers', re.compile(r"(MySQL\.\w+\([^\n]*UPDATE\s+players\s+SET\s+money|exports\.oxmysql:\w+\([^\n]*JSON_SET\([^\n]*money)", re.IGNORECASE), 'manual'),
    PatternSpec('U6', 'INFO', 'qb-banking society/shared account export is Phase B scope', re.compile(r"exports\[?['\"]qb-banking['\"]\]?:(AddMoney|RemoveMoney|GetAccount|GetAccountBalance|CreatePlayerAccount)"), 'manual'),
    PatternSpec('U7', 'INFO', 'cash-as-item inventory flow is Phase B scope', re.compile(r"exports\[?['\"](?:qb-inventory|ox_inventory)['\"]\]?:(?:AddItem|RemoveItem)\(\s*[^,]+,\s*['\"](?:money|cash)['\"]"), 'manual'),
    PatternSpec('U8', 'MEDIUM', 'custom function call amount unit is unknown', re.compile(r"\b\w+\.Functions\.(AddMoney|RemoveMoney)\(\s*['\"]bank['\"]\s*,\s*[\w.]+\([^)]*\)"), 'manual'),
    PatternSpec('U9', 'HIGH', 'amount identifier suggests minor/cents and must not be double-shifted', re.compile(r"\b\w+\.Functions\.(AddMoney|RemoveMoney)\(\s*['\"]bank['\"]\s*,\s*\w*(?:_minor|_cents|_centavos|Minor|Cents)\b"), 'manual'),
)

S4_READ_RE = re.compile(r"\b(\w+)\.PlayerData\.money\.bank\b")
BANK_FUNCTION_RE = re.compile(r"(?P<var>\b\w+)\.Functions\.(?P<method>AddMoney|RemoveMoney|SetMoney)\s*\(")
IF_REMOVE_RE = re.compile(r"^(?P<indent>\s*)if\s+(?P<var>\w+)\.Functions\.RemoveMoney\s*\(")
ELSEIF_REMOVE_RE = re.compile(r"^(?P<indent>\s*)elseif\s+(?P<var>\w+)\.Functions\.RemoveMoney\s*\(")


def iter_unsafe_specs() -> Iterable[PatternSpec]:
    return UNSAFE_PATTERNS


def classify_unsafe_line(line: str) -> list[PatternSpec]:
    return [spec for spec in UNSAFE_PATTERNS if spec.pattern_id != 'U3' and spec.regex.search(line)]


def classify_unsafe_document(text: str) -> list[tuple[PatternSpec, int, str]]:
    hits: list[tuple[PatternSpec, int, str]] = []
    for spec in UNSAFE_PATTERNS:
        if spec.pattern_id != 'U3':
            continue
        for match in spec.regex.finditer(text):
            line_no = text[:match.start()].count('\n') + 1
            original = text[match.start():match.end()].splitlines()[0].strip()
            hits.append((spec, line_no, original))
    return hits
