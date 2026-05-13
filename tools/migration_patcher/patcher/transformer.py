from __future__ import annotations

import difflib
import hashlib
from dataclasses import dataclass, field
from pathlib import Path

from . import __version__
from .binding_resolver import BindingKind, resolve_binding
from .patterns import ELSEIF_REMOVE_RE, IF_REMOVE_RE, S4_READ_RE, classify_unsafe_document, classify_unsafe_line
from .safety import contains_marker, has_minor_unit_hint, is_float_literal, make_marker, to_minor_expr


@dataclass
class PatchEntry:
    resource: str
    file_path: str
    line: int
    pattern_id: str
    original: str
    patched: str
    binding: str = ''


@dataclass
class ManualEntry:
    resource: str
    file_path: str
    line: int
    pattern_id: str
    severity: str
    original: str
    reason: str
    recommendation: str = ''


@dataclass
class TransformResult:
    original_text: str
    patched_text: str
    auto_entries: list[PatchEntry] = field(default_factory=list)
    manual_entries: list[ManualEntry] = field(default_factory=list)
    skipped_reason: str | None = None

    @property
    def changed(self) -> bool:
        return self.original_text != self.patched_text

    def unified_diff(self, fromfile: str, tofile: str) -> str:
        return ''.join(difflib.unified_diff(
            self.original_text.splitlines(keepends=True),
            self.patched_text.splitlines(keepends=True),
            fromfile=fromfile,
            tofile=tofile,
        ))


def split_lua_args(arg_text: str) -> list[str]:
    args: list[str] = []
    current: list[str] = []
    quote: str | None = None
    escape = False
    depth = 0
    pairs = {'(': ')', '{': '}', '[': ']'}
    closers = set(pairs.values())
    for char in arg_text:
        if quote:
            current.append(char)
            if escape:
                escape = False
            elif char == '\\':
                escape = True
            elif char == quote:
                quote = None
            continue
        if char in ('"', "'"):
            quote = char
            current.append(char)
            continue
        if char in pairs:
            depth += 1
            current.append(char)
            continue
        if char in closers and depth > 0:
            depth -= 1
            current.append(char)
            continue
        if char == ',' and depth == 0:
            args.append(''.join(current).strip())
            current = []
            continue
        current.append(char)
    if current or arg_text.strip():
        args.append(''.join(current).strip())
    return args


def extract_call_args(line: str, player_var: str, method: str) -> tuple[list[str], str] | None:
    needle = f'{player_var}.Functions.{method}'
    start = line.find(needle)
    if start < 0:
        return None
    open_idx = line.find('(', start + len(needle))
    if open_idx < 0:
        return None
    quote: str | None = None
    escape = False
    depth = 0
    for idx in range(open_idx, len(line)):
        char = line[idx]
        if quote:
            if escape:
                escape = False
            elif char == '\\':
                escape = True
            elif char == quote:
                quote = None
            continue
        if char in ('"', "'"):
            quote = char
            continue
        if char == '(':
            depth += 1
            continue
        if char == ')':
            depth -= 1
            if depth == 0:
                return split_lua_args(line[open_idx + 1:idx]), line[idx + 1:]
    return None


def _hash_name(file_path: str, line_no: int, amount_expr: str) -> str:
    raw = f'{file_path}:{line_no}:{amount_expr}'.encode('utf-8')
    return hashlib.md5(raw).hexdigest()[:8]


def _manual(resource: str, file_path: str, line: int, pattern_id: str, severity: str, original: str, reason: str, recommendation: str = '') -> ManualEntry:
    return ManualEntry(resource, file_path, line, pattern_id, severity, original.strip(), reason, recommendation)


def _can_transform_amount(expr: str) -> tuple[bool, str | None]:
    if is_float_literal(expr):
        return False, 'float literal amount is not safely migratable'
    if has_minor_unit_hint(expr):
        return False, 'amount expression suggests minor/cents units; double-shift risk'
    return True, None


def _build_call(export_name: str, target_expr: str, amount_expr: str, reason_expr: str) -> str:
    return f'exports.sonar_bank_app:{export_name}({target_expr}, {to_minor_expr(amount_expr)}, {reason_expr}, nil)'


def transform_lua_text(text: str, resource: str, file_path: str) -> TransformResult:
    result = TransformResult(original_text=text, patched_text=text)
    if contains_marker(text):
        result.skipped_reason = 'already patched marker found'
        return result

    for spec, line_no, original in classify_unsafe_document(text):
        result.manual_entries.append(_manual(resource, file_path, line_no, spec.pattern_id, spec.severity, original, spec.description))

    lines = text.splitlines(keepends=True)
    out_lines: list[str] = []
    for idx, line in enumerate(lines):
        line_no = idx + 1
        newline = '\n' if line.endswith('\n') else ''
        body = line[:-1] if newline else line
        stripped = body.strip()

        for spec in classify_unsafe_line(body):
            result.manual_entries.append(_manual(resource, file_path, line_no, spec.pattern_id, spec.severity, stripped, spec.description))

        if S4_READ_RE.search(body):
            result.manual_entries.append(_manual(resource, file_path, line_no, 'S4', 'INFO', stripped, 'GetBalance PlayerData read is detected but skipped in Phase A'))

        if any(entry.line == line_no and entry.pattern_id in {'U2', 'U8', 'U9'} for entry in result.manual_entries):
            out_lines.append(line)
            continue

        if ELSEIF_REMOVE_RE.search(body):
            result.manual_entries.append(_manual(resource, file_path, line_no, 'S2', 'MEDIUM', stripped, 'elseif RemoveMoney chain requires manual control-flow rewrite'))
            out_lines.append(line)
            continue

        if stripped.startswith('if not ') and '.Functions.RemoveMoney' in body:
            result.manual_entries.append(_manual(resource, file_path, line_no, 'S2', 'MEDIUM', stripped, 'negated RemoveMoney if-check requires manual control-flow rewrite'))
            out_lines.append(line)
            continue

        if_match = IF_REMOVE_RE.search(body)
        if if_match:
            player_var = if_match.group('var')
            parsed = extract_call_args(body, player_var, 'RemoveMoney')
            binding = resolve_binding([l.rstrip('\n') for l in lines], idx, player_var)
            if parsed and len(parsed[0]) >= 3 and parsed[0][0].strip("'\"") == 'bank' and binding and binding.kind == BindingKind.ONLINE:
                amount_expr, reason_expr = parsed[0][1], parsed[0][2]
                safe, unsafe_reason = _can_transform_amount(amount_expr)
                if safe:
                    indent = if_match.group('indent')
                    ok_name = f'ok_{_hash_name(file_path, line_no, amount_expr)}'
                    call = _build_call('RemoveMoney', binding.source_expr, amount_expr, reason_expr)
                    patched_lines = [
                        f'{indent}{make_marker("S2", line_no)}{newline}',
                        f'{indent}local {ok_name}, _, _ = {call}{newline}',
                        f'{indent}if {ok_name} then{newline}',
                    ]
                    out_lines.extend(patched_lines)
                    result.auto_entries.append(PatchEntry(resource, file_path, line_no, 'S2', stripped, ''.join(patched_lines).strip(), binding.original))
                    continue
                result.manual_entries.append(_manual(resource, file_path, line_no, 'U9', 'HIGH', stripped, unsafe_reason or 'unsafe amount expression'))
            else:
                result.manual_entries.append(_manual(resource, file_path, line_no, 'S2', 'MEDIUM', stripped, 'RemoveMoney if-check binding unresolved'))
            out_lines.append(line)
            continue

        transformed = False
        for method in ('AddMoney', 'RemoveMoney'):
            marker = f'.Functions.{method}'
            if marker not in body:
                continue
            if stripped.startswith(('if ', 'elseif ', 'return ')):
                result.manual_entries.append(_manual(resource, file_path, line_no, 'S1', 'MEDIUM', stripped, 'non-bare money call requires manual control-flow rewrite'))
                break
            prefix = body.split(marker, 1)[0]
            player_var = prefix.strip().split()[-1].split('.')[-1] if prefix.strip() else ''
            if not player_var.isidentifier():
                continue
            parsed = extract_call_args(body, player_var, method)
            if not parsed or len(parsed[0]) < 3:
                continue
            args, suffix = parsed
            if args[0].strip("'\"") != 'bank':
                continue
            binding = resolve_binding([l.rstrip('\n') for l in lines], idx, player_var)
            if not binding:
                result.manual_entries.append(_manual(resource, file_path, line_no, 'S1', 'MEDIUM', stripped, 'player binding unresolved'))
                break
            amount_expr, reason_expr = args[1], args[2]
            safe, unsafe_reason = _can_transform_amount(amount_expr)
            if not safe:
                result.manual_entries.append(_manual(resource, file_path, line_no, 'U9', 'HIGH', stripped, unsafe_reason or 'unsafe amount expression'))
                break
            export_name = method if binding.kind == BindingKind.ONLINE else f'{method}ByCitizen'
            target_expr = binding.source_expr
            call = _build_call(export_name, target_expr, amount_expr, reason_expr)
            indent = body[:len(body) - len(body.lstrip())]
            pattern_id = 'S3' if binding.kind == BindingKind.OFFLINE else 'S1'
            patched = f'{indent}{call}{suffix}'
            out_lines.append(f'{indent}{make_marker(pattern_id, line_no)}{newline}')
            out_lines.append(f'{patched}{newline}')
            result.auto_entries.append(PatchEntry(resource, file_path, line_no, pattern_id, stripped, patched.strip(), binding.original))
            transformed = True
            break
        if transformed:
            continue
        out_lines.append(line)

    result.patched_text = ''.join(out_lines)
    return result


def transform_lua_file(path: Path, resource_root: Path) -> TransformResult:
    text = path.read_text(encoding='utf-8')
    resource = resource_root.name
    rel = path.relative_to(resource_root).as_posix()
    return transform_lua_text(text, resource, rel)
