from patcher.binding_resolver import BindingKind, resolve_binding


def test_online_binding_source_alias():
    lines = ['function x()', 'local Player = QBCore.Functions.GetPlayer(src)', "Player.Functions.AddMoney('bank', amount, 'r')"]
    binding = resolve_binding(lines, 2, 'Player')
    assert binding is not None
    assert binding.kind == BindingKind.ONLINE
    assert binding.source_expr == 'src'


def test_offline_binding_citizenid():
    lines = ['function x()', 'local Offline = QBCore.Functions.GetOfflinePlayer(citizenid)', "Offline.Functions.AddMoney('bank', amount, 'r')"]
    binding = resolve_binding(lines, 2, 'Offline')
    assert binding is not None
    assert binding.kind == BindingKind.OFFLINE
    assert binding.source_expr == 'citizenid'


def test_get_player_by_citizenid_online_source_derivation():
    lines = ['function x()', 'local SellerData = QBCore.Functions.GetPlayerByCitizenId(SellerCitizenId)', "SellerData.Functions.AddMoney('bank', amount, 'r')"]
    binding = resolve_binding(lines, 2, 'SellerData')
    assert binding is not None
    assert binding.kind == BindingKind.ONLINE
    assert binding.source_expr == 'SellerData.PlayerData.source'


def test_nested_getplayer_argument_preserved():
    lines = ['function x()', 'local billed = QBCore.Functions.GetPlayer(tonumber(args[1]))', "billed.Functions.RemoveMoney('bank', amount, 'r')"]
    binding = resolve_binding(lines, 2, 'billed')
    assert binding is not None
    assert binding.source_expr == 'tonumber(args[1])'
