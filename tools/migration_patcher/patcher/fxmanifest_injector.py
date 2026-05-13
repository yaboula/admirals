from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

DEPENDENCY = 'sonar_bank_app'


@dataclass
class ManifestResult:
    original_text: str
    patched_text: str
    injected: bool = False

    @property
    def changed(self) -> bool:
        return self.original_text != self.patched_text


def has_dependency(text: str) -> bool:
    return re.search(r"['\"]sonar_bank_app['\"]", text) is not None


def inject_dependency(text: str) -> ManifestResult:
    if has_dependency(text):
        return ManifestResult(text, text, False)

    block_re = re.compile(r"(?P<head>dependencies\s*\{)(?P<body>[\s\S]*?)(?P<tail>\n\})", re.MULTILINE)
    match = block_re.search(text)
    if match:
        body = match.group('body')
        insertion = body
        stripped = insertion.rstrip()
        if stripped and not stripped.endswith(','):
            last_line_start = stripped.rfind('\n') + 1
            insertion = stripped[:last_line_start] + stripped[last_line_start:] + ',' + insertion[len(stripped):]
        if body and not body.endswith('\n'):
            insertion += '\n'
        insertion += "    'sonar_bank_app',"
        patched = text[:match.start('body')] + insertion + text[match.start('tail'):]
        return ManifestResult(text, patched, True)

    dependency_line = re.search(r"^dependency\s+['\"][^'\"]+['\"]\s*$", text, re.MULTILINE)
    if dependency_line:
        insert_at = dependency_line.end()
        patched = text[:insert_at] + "\ndependency 'sonar_bank_app'" + text[insert_at:]
        return ManifestResult(text, patched, True)

    fx_line = re.search(r"^fx_version\s+['\"][^'\"]+['\"]\s*$", text, re.MULTILINE)
    block = "\ndependencies {\n    'sonar_bank_app',\n}\n"
    if fx_line:
        insert_at = fx_line.end()
        patched = text[:insert_at] + block + text[insert_at:]
    else:
        patched = text.rstrip() + block + '\n'
    return ManifestResult(text, patched, True)


def inject_manifest_file(path: Path) -> ManifestResult:
    return inject_dependency(path.read_text(encoding='utf-8'))
