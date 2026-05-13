from __future__ import annotations

import fnmatch
import shutil
from pathlib import Path

import click

from .fxmanifest_injector import inject_manifest_file
from .report import RunReport, write_reports
from .safety import is_qb_core_resource, is_real_server_path
from .transformer import transform_lua_file

LUA_GLOBS = ('*.lua',)
MANIFEST_NAMES = ('fxmanifest.lua', '__resource.lua')


def iter_resources(source_dir: Path, filter_resource: str | None) -> list[Path]:
    resources = [p for p in source_dir.iterdir() if p.is_dir() and not is_qb_core_resource(p)]
    if filter_resource:
        resources = [p for p in resources if fnmatch.fnmatch(p.name, filter_resource)]
    return sorted(resources, key=lambda p: p.name.lower())


def iter_lua_files(resource: Path) -> list[Path]:
    return sorted([p for p in resource.rglob('*.lua') if p.name not in MANIFEST_NAMES], key=lambda p: p.as_posix())


def manifest_for(resource: Path) -> Path | None:
    for name in MANIFEST_NAMES:
        candidate = resource / name
        if candidate.exists():
            return candidate
    return None


def write_diff(output_dir: Path, resource: Path, rel_file: str, diff: str) -> None:
    target = output_dir / resource.name / f'{rel_file}.diff'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(diff, encoding='utf-8')


def backup_path(output_dir: Path, resource: Path, rel_file: str) -> Path:
    return output_dir / resource.name / f'{rel_file}.bak'


def apply_file(path: Path, patched_text: str, output_dir: Path, resource: Path, rel_file: str) -> None:
    bak = backup_path(output_dir, resource, rel_file)
    bak.parent.mkdir(parents=True, exist_ok=True)
    if not bak.exists():
        bak.write_text(path.read_text(encoding='utf-8'), encoding='utf-8')
    path.write_text(patched_text, encoding='utf-8')


def rollback(output_dir: Path, source_dir: Path, filter_resource: str | None) -> None:
    for resource in iter_resources(source_dir, filter_resource):
        resource_output = output_dir / resource.name
        if not resource_output.exists():
            continue
        for bak in resource_output.rglob('*.bak'):
            rel_raw = str(bak.relative_to(resource_output))[:-4]
            target = resource / rel_raw
            if target.exists():
                target.write_text(bak.read_text(encoding='utf-8'), encoding='utf-8')


@click.command(context_settings={'help_option_names': ['-h', '--help']})
@click.argument('source_dir', type=click.Path(exists=True, file_okay=False, dir_okay=True, path_type=Path))
@click.option('--dry-run', 'dry_run', is_flag=True, default=False, help='Generate diffs + reports without modifying files.')
@click.option('--apply', 'apply_changes', is_flag=True, default=False, help='Apply patches in-place with .bak backup.')
@click.option('--filter-resource', default=None, help='Glob pattern to filter resources, e.g. qb-*shop.')
@click.option('--money-types', default='bank', help='Comma-separated money types. Phase A supports bank only by default.')
@click.option('--output-dir', type=click.Path(file_okay=False, dir_okay=True, path_type=Path), default=Path('migration_output'), help='Output directory.')
@click.option('--rollback', 'rollback_flag', is_flag=True, default=False, help='Restore .bak files from output dir.')
@click.option('--no-color', is_flag=True, default=False, help='Disable ANSI color.')
@click.option('--verbose', is_flag=True, default=False, help='Verbose logging.')
def main(source_dir: Path, dry_run: bool, apply_changes: bool, filter_resource: str | None, money_types: str, output_dir: Path, rollback_flag: bool, no_color: bool, verbose: bool) -> None:
    source_dir = source_dir.resolve()
    output_dir = output_dir.resolve()
    scope = [m.strip() for m in money_types.split(',') if m.strip()]
    if scope != ['bank']:
        raise click.ClickException('Phase 5.6.A supports --money-types=bank only. cash/crypto are Phase B.')
    if apply_changes and dry_run:
        raise click.ClickException('--apply and --dry-run are mutually exclusive')
    if apply_changes and is_real_server_path(source_dir):
        raise click.ClickException('Refusing --apply against real D:/FiveM_Server/Sonar path in Phase 5.6.A')
    if rollback_flag and is_real_server_path(source_dir):
        raise click.ClickException('Refusing --rollback against real D:/FiveM_Server/Sonar path in Phase 5.6.A')
    if rollback_flag:
        rollback(output_dir, source_dir, filter_resource)
        click.echo(f'rollback completed from {output_dir}')
        return

    mode = 'apply' if apply_changes else 'dry-run'
    report = RunReport(mode=mode, scope_money_types=scope)
    resources = iter_resources(source_dir, filter_resource)
    report.resources_scanned = len(resources)

    for resource in resources:
        res_summary = report.resource(resource.name)
        lua_files = iter_lua_files(resource)
        res_summary.files_scanned = len(lua_files)
        resource_changed = False
        manifest_pending = False
        for lua_file in lua_files:
            transform = transform_lua_file(lua_file, resource)
            for entry in transform.auto_entries:
                report.add_auto(entry)
            for entry in transform.manual_entries:
                report.add_manual(entry)
            if transform.changed:
                rel_file = lua_file.relative_to(resource).as_posix()
                write_diff(output_dir, resource, rel_file, transform.unified_diff(f'a/{rel_file}', f'b/{rel_file}'))
                manifest_pending = True
                resource_changed = True
                if apply_changes:
                    apply_file(lua_file, transform.patched_text, output_dir, resource, rel_file)
        if manifest_pending:
            manifest = manifest_for(resource)
            if manifest:
                manifest_result = inject_manifest_file(manifest)
                if manifest_result.changed:
                    rel_manifest = manifest.relative_to(resource).as_posix()
                    diff = ''.join(__import__('difflib').unified_diff(
                        manifest_result.original_text.splitlines(keepends=True),
                        manifest_result.patched_text.splitlines(keepends=True),
                        fromfile=f'a/{rel_manifest}',
                        tofile=f'b/{rel_manifest}',
                    ))
                    write_diff(output_dir, resource, rel_manifest, diff)
                    report.add_fxmanifest(resource.name, rel_manifest)
                    if apply_changes:
                        apply_file(manifest, manifest_result.patched_text, output_dir, resource, rel_manifest)
        if verbose and resource_changed:
            click.echo(f'processed {resource.name}')

    write_reports(report, output_dir)
    click.echo(f'{mode} completed: {len(report.auto_entries)} auto, {len(report.manual_entries)} manual, output={output_dir}')
