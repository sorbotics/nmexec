import pytest

# __main__ imports yolo9 and the server module; skip if deps are missing
pytest.importorskip("yolo9.detect_dual")
pytest.importorskip("nmexec.server")

from nmexec import __main__ as entry  # noqa: E402


def test_detect_dual_calls_detect_dual_parse_opt_and_main(monkeypatch):
    calls = []
    monkeypatch.setattr(entry, "detect_dual_parse_opt", lambda: "opt")
    monkeypatch.setattr(entry, "detect_dual_main", calls.append)
    monkeypatch.setattr(entry, "detect_main", lambda opt: calls.append("bad"))

    entry.detect_dual()

    assert calls == ["opt"]
