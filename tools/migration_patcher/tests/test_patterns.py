from patcher.patterns import S4_READ_RE, classify_unsafe_document, classify_unsafe_line, iter_unsafe_specs


def test_all_pattern_ids_present():
    ids = {spec.pattern_id for spec in iter_unsafe_specs()}
    assert ids == {'U1', 'U2', 'U3', 'U4', 'U5', 'U6', 'U7', 'U8', 'U9'}
    assert S4_READ_RE.search('Player.PlayerData.money.bank')


def test_unsafe_line_patterns():
    samples = {
        'U1': "Player.Functions.AddMoney('cash', amount, 'r')",
        'U2': "Player.Functions.SetMoney('bank', amount, 'r')",
        'U4': 'Player.PlayerData.money.bank = 10',
        'U5': "MySQL.update('UPDATE players SET money = ?', {money})",
        'U6': "exports['qb-banking']:AddMoney('realestate', 5, 'r')",
        'U7': "exports['qb-inventory']:AddItem(src, 'cash', 1)",
        'U8': "Player.Functions.AddMoney('bank', GetPrice())",
        'U9': "Player.Functions.RemoveMoney('bank', amount_minor, 'r')",
    }
    for expected, line in samples.items():
        assert expected in {spec.pattern_id for spec in classify_unsafe_line(line)}


def test_u3_document_pattern():
    text = "for _, p in pairs(QBCore.Functions.GetQBPlayers()) do\n  p.Functions.AddMoney('bank', 1, 'r')\nend"
    hits = classify_unsafe_document(text)
    assert hits[0][0].pattern_id == 'U3'
