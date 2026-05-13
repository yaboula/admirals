from patcher.fxmanifest_injector import inject_dependency


def test_fxmanifest_no_deps(fixtures_dir):
    result = inject_dependency((fixtures_dir / 'fxmanifest_no_deps.in.lua').read_text())
    assert result.patched_text == (fixtures_dir / 'fxmanifest_no_deps.expected.lua').read_text()
    assert result.injected


def test_fxmanifest_existing_deps(fixtures_dir):
    result = inject_dependency((fixtures_dir / 'fxmanifest_existing_deps.in.lua').read_text())
    assert result.patched_text == (fixtures_dir / 'fxmanifest_existing_deps.expected.lua').read_text()
    assert result.injected


def test_fxmanifest_already_present(fixtures_dir):
    source = (fixtures_dir / 'fxmanifest_already_present.in.lua').read_text()
    result = inject_dependency(source)
    assert result.patched_text == source
    assert not result.injected
