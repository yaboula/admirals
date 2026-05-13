from patcher.transformer import transform_lua_text


GOLDENS = [
    'qb_shops_main',
    'qb_vehicleshop_server',
    'qb_pawnshop_main',
    'qb_houses_main',
    'qb_vehiclesales_main',
    'qb_drugs_cornerselling',
    'offline_player',
]


def test_golden_fixtures(fixtures_dir):
    for name in GOLDENS:
        source = (fixtures_dir / f'{name}.in.lua').read_text()
        expected = (fixtures_dir / f'{name}.expected.lua').read_text()
        result = transform_lua_text(source, resource=name, file_path='server/main.lua')
        assert result.patched_text == expected, name


def test_idempotent_marker_skip(fixtures_dir):
    patched = (fixtures_dir / 'qb_pawnshop_main.expected.lua').read_text()
    result = transform_lua_text(patched, resource='qb-pawnshop', file_path='server/main.lua')
    assert result.skipped_reason == 'already patched marker found'
    assert result.patched_text == patched


def test_minor_suffix_manual_not_patched():
    text = "local Player = QBCore.Functions.GetPlayer(src)\nPlayer.Functions.AddMoney('bank', amount_minor, 'r')\n"
    result = transform_lua_text(text, resource='x', file_path='server.lua')
    assert result.patched_text == text
    assert any(entry.pattern_id == 'U9' for entry in result.manual_entries)


def test_unresolved_binding_manual_not_patched():
    text = "function process(Player)\n  Player.Functions.AddMoney('bank', amount, 'r')\nend\n"
    result = transform_lua_text(text, resource='x', file_path='server.lua')
    assert result.patched_text == text
    assert any(entry.pattern_id == 'S1' for entry in result.manual_entries)
