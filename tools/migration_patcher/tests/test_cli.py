import json
from click.testing import CliRunner

from patcher.cli import main


def make_resource(root, name='qb-test'):
    resource = root / name
    resource.mkdir()
    (resource / 'fxmanifest.lua').write_text("fx_version 'cerulean'\ngame 'gta5'\n")
    (resource / 'server.lua').write_text("local Player = QBCore.Functions.GetPlayer(src)\nPlayer.Functions.AddMoney('bank', amount, 'r')\n")
    return resource


def test_cli_dry_run(tmp_path):
    source = tmp_path / 'source'
    source.mkdir()
    make_resource(source)
    out = tmp_path / 'out'
    result = CliRunner().invoke(main, ['--dry-run', '--output-dir', str(out), str(source)])
    assert result.exit_code == 0, result.output
    summary = json.loads((out / 'summary.json').read_text())
    assert summary['totals']['auto_patched_call_sites'] == 1
    assert (out / 'qb-test' / 'server.lua.diff').exists()
    assert (out / 'qb-test' / 'fxmanifest.lua.diff').exists()
    assert "Player.Functions.AddMoney('bank'" in (source / 'qb-test' / 'server.lua').read_text()


def test_cli_filter_resource(tmp_path):
    source = tmp_path / 'source'
    source.mkdir()
    make_resource(source, 'qb-hit')
    make_resource(source, 'qb-skip')
    out = tmp_path / 'out'
    result = CliRunner().invoke(main, ['--dry-run', '--filter-resource', 'qb-hit', '--output-dir', str(out), str(source)])
    assert result.exit_code == 0
    summary = json.loads((out / 'summary.json').read_text())
    assert summary['totals']['resources_scanned'] == 1


def test_cli_apply_and_rollback(tmp_path):
    source = tmp_path / 'source'
    source.mkdir()
    resource = make_resource(source)
    original = (resource / 'server.lua').read_text()
    out = tmp_path / 'out'
    apply_result = CliRunner().invoke(main, ['--apply', '--output-dir', str(out), str(source)])
    assert apply_result.exit_code == 0, apply_result.output
    assert 'SONAR_PATCHED' in (resource / 'server.lua').read_text()
    rollback_result = CliRunner().invoke(main, ['--rollback', '--output-dir', str(out), str(source)])
    assert rollback_result.exit_code == 0, rollback_result.output
    assert (resource / 'server.lua').read_text() == original


def test_cli_reject_non_bank_money_types(tmp_path):
    source = tmp_path / 'source'
    source.mkdir()
    result = CliRunner().invoke(main, ['--money-types', 'bank,cash', str(source)])
    assert result.exit_code != 0
    assert 'bank only' in result.output
