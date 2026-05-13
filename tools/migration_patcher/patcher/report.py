from __future__ import annotations

import json
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from . import __version__
from .transformer import ManualEntry, PatchEntry

SEVERITY_ORDER = {'CRITICAL': 0, 'HIGH': 1, 'MEDIUM': 2, 'INFO': 3}


@dataclass
class ResourceSummary:
    name: str
    files_scanned: int = 0
    auto_patched: int = 0
    manual_review: int = 0
    files_touched: set[str] = field(default_factory=set)
    patterns: Counter[str] = field(default_factory=Counter)


@dataclass
class RunReport:
    mode: str
    scope_money_types: list[str]
    resources_scanned: int = 0
    auto_entries: list[PatchEntry] = field(default_factory=list)
    manual_entries: list[ManualEntry] = field(default_factory=list)
    fxmanifest_injections: list[str] = field(default_factory=list)
    resource_summaries: dict[str, ResourceSummary] = field(default_factory=dict)

    def resource(self, name: str) -> ResourceSummary:
        if name not in self.resource_summaries:
            self.resource_summaries[name] = ResourceSummary(name=name)
        return self.resource_summaries[name]

    def add_auto(self, entry: PatchEntry) -> None:
        self.auto_entries.append(entry)
        summary = self.resource(entry.resource)
        summary.auto_patched += 1
        summary.files_touched.add(entry.file_path)
        summary.patterns[entry.pattern_id] += 1

    def add_manual(self, entry: ManualEntry) -> None:
        self.manual_entries.append(entry)
        summary = self.resource(entry.resource)
        summary.manual_review += 1
        summary.patterns[entry.pattern_id] += 1

    def add_fxmanifest(self, resource: str, path: str) -> None:
        self.fxmanifest_injections.append(f'{resource}/{path}')
        self.resource(resource).files_touched.add(path)


def write_reports(report: RunReport, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / 'auto_patched.md').write_text(render_auto(report), encoding='utf-8')
    (output_dir / 'manual_review.md').write_text(render_manual(report), encoding='utf-8')
    (output_dir / 'summary.json').write_text(json.dumps(summary_dict(report), indent=2, sort_keys=True), encoding='utf-8')


def render_auto(report: RunReport) -> str:
    lines = ['# Auto patched call sites', '']
    if not report.auto_entries:
        lines += ['No auto patches generated.', '']
    for entry in report.auto_entries:
        lines += [
            f'### {entry.resource}/{entry.file_path}:{entry.line}',
            f'- Pattern: {entry.pattern_id}',
            f'- Original: `{entry.original}`',
            f'- Patched: `{entry.patched}`',
            f'- Source binding: `{entry.binding}`',
            '',
        ]
    if report.fxmanifest_injections:
        lines += ['## fxmanifest dependency injections', '']
        for item in report.fxmanifest_injections:
            lines.append(f'- `{item}`')
        lines.append('')
    return '\n'.join(lines)


def render_manual(report: RunReport) -> str:
    lines = ['# Manual review call sites', '']
    entries = sorted(report.manual_entries, key=lambda e: (SEVERITY_ORDER.get(e.severity, 99), e.resource, e.file_path, e.line, e.pattern_id))
    if not entries:
        lines += ['No manual review entries.', '']
    for entry in entries:
        lines += [
            f'### {entry.resource}/{entry.file_path}:{entry.line} — {entry.pattern_id} {entry.severity}',
            f'- Original: `{entry.original}`',
            f'- Reason: {entry.reason}',
        ]
        if entry.recommendation:
            lines.append(f'- Recommendation: {entry.recommendation}')
        lines.append('')
    return '\n'.join(lines)


def summary_dict(report: RunReport) -> dict[str, Any]:
    pattern_distribution: Counter[str] = Counter()
    for entry in report.auto_entries:
        pattern_distribution[entry.pattern_id] += 1
    for entry in report.manual_entries:
        pattern_distribution[entry.pattern_id] += 1

    resources = []
    for name in sorted(report.resource_summaries):
        res = report.resource_summaries[name]
        resources.append({
            'name': name,
            'files_scanned': res.files_scanned,
            'auto_patched': res.auto_patched,
            'manual_review': res.manual_review,
            'files_touched': len(res.files_touched),
            'patterns': dict(sorted(res.patterns.items())),
        })

    return {
        'phase': '5.6',
        'patcher_version': __version__,
        'scope_money_types': report.scope_money_types,
        'executed_at': datetime.now(timezone.utc).isoformat(),
        'mode': report.mode,
        'totals': {
            'resources_scanned': report.resources_scanned,
            'resources_with_hits': len([r for r in resources if r['auto_patched'] or r['manual_review']]),
            'files_touched': len({(e.resource, e.file_path) for e in report.auto_entries}) + len(report.fxmanifest_injections),
            'auto_patched_call_sites': len(report.auto_entries),
            'manual_review_call_sites': len(report.manual_entries),
            'fxmanifest_injections': len(report.fxmanifest_injections),
        },
        'pattern_distribution': dict(sorted(pattern_distribution.items())),
        'resources': resources,
    }
