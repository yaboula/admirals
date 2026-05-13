from __future__ import annotations

import re
from dataclasses import dataclass
from enum import Enum
from typing import Sequence


class BindingKind(str, Enum):
    ONLINE = 'online'
    OFFLINE = 'offline'


@dataclass(frozen=True)
class Binding:
    var_name: str
    kind: BindingKind
    source_expr: str
    binding_line: int
    original: str


BINDING_RE = re.compile(
    r"local\s+(?P<var>\w+)\s*=\s*QBCore\.Functions\.(?P<fn>GetPlayer|GetOfflinePlayer|GetPlayerByCitizenId)\s*\(\s*(?P<arg>.*)\s*\)\s*$"
)

FUNCTION_START_RE = re.compile(r"\b(function|RegisterNetEvent|CreateThread|AddEventHandler|QBCore\.Functions\.CreateCallback)\b")


def scope_start_for_line(lines: Sequence[str], line_index: int) -> int:
    idx = max(0, line_index)
    while idx >= 0:
        if FUNCTION_START_RE.search(lines[idx]):
            return idx
        idx -= 1
    return 0


def bindings_before(lines: Sequence[str], line_index: int) -> dict[str, Binding]:
    start = scope_start_for_line(lines, line_index)
    found: dict[str, Binding] = {}
    for idx in range(start, line_index + 1):
        match = BINDING_RE.search(lines[idx])
        if not match:
            continue
        var_name = match.group('var')
        fn = match.group('fn')
        arg = match.group('arg').strip()
        if fn == 'GetOfflinePlayer':
            binding = Binding(var_name, BindingKind.OFFLINE, arg, idx + 1, lines[idx].strip())
        elif fn == 'GetPlayerByCitizenId':
            binding = Binding(var_name, BindingKind.ONLINE, f'{var_name}.PlayerData.source', idx + 1, lines[idx].strip())
        else:
            binding = Binding(var_name, BindingKind.ONLINE, arg, idx + 1, lines[idx].strip())
        found[var_name] = binding
    return found


def resolve_binding(lines: Sequence[str], line_index: int, player_var: str) -> Binding | None:
    return bindings_before(lines, line_index).get(player_var)
