from pathlib import Path

from patcher.safety import contains_marker, has_minor_unit_hint, is_real_server_path, to_minor_expr


def test_marker_and_minor_hints():
    assert contains_marker('-- SONAR_PATCHED v1: S1 orig_line=1')
    assert has_minor_unit_hint('amount_minor')
    assert has_minor_unit_hint('totalCents')
    assert not has_minor_unit_hint('amount')


def test_to_minor_expr():
    assert to_minor_expr('50') == '5000'
    assert to_minor_expr('amount') == '(amount) * 100'
    assert to_minor_expr('math.floor(payout * mod)') == 'math.floor((payout * mod) * 100)'


def test_real_server_path_guard():
    assert is_real_server_path(Path('D:/FiveM_Server/Sonar/resources/[qb]'))
    assert not is_real_server_path(Path('D:/theBigProject/sandbox_qb_snapshot'))
