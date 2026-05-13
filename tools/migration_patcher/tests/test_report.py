from patcher.report import RunReport, render_auto, render_manual, summary_dict
from patcher.transformer import ManualEntry, PatchEntry


def test_report_render_and_summary():
    report = RunReport(mode='dry-run', scope_money_types=['bank'], resources_scanned=1)
    report.add_auto(PatchEntry('qb-test', 'server.lua', 1, 'S1', 'old', 'new', 'binding'))
    report.add_manual(ManualEntry('qb-test', 'server.lua', 2, 'U1', 'INFO', 'cash', 'cash scope'))
    report.add_fxmanifest('qb-test', 'fxmanifest.lua')
    assert 'qb-test/server.lua:1' in render_auto(report)
    assert 'U1 INFO' in render_manual(report)
    summary = summary_dict(report)
    assert summary['totals']['auto_patched_call_sites'] == 1
    assert summary['pattern_distribution']['S1'] == 1
    assert summary['pattern_distribution']['U1'] == 1
