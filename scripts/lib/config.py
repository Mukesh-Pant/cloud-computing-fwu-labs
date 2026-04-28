"""Config loader shared by personalize.py and build_report.py.

Loads `config.yaml` from the repo root and exposes it as a dotted-access
namespace so consumers can write `cfg.student.suffix` instead of
`cfg["student"]["suffix"]`.
"""
from __future__ import annotations

import re
from pathlib import Path
from types import SimpleNamespace
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parents[2]
CONFIG_PATH = ROOT / "config.yaml"

SUFFIX_PATTERN = re.compile(r"^[a-z][a-z0-9-]{1,30}$")


def _ns(d: Any) -> Any:
    """Recursively convert nested dicts to SimpleNamespace for dotted access."""
    if isinstance(d, dict):
        return SimpleNamespace(**{k: _ns(v) for k, v in d.items()})
    if isinstance(d, list):
        return [_ns(x) for x in d]
    return d


def load(path: Path = CONFIG_PATH) -> SimpleNamespace:
    """Load config.yaml and return a SimpleNamespace tree.

    Raises FileNotFoundError if the file is missing.
    Raises ValueError if `student.suffix` is not a valid AWS-friendly token.
    """
    if not path.exists():
        raise FileNotFoundError(f"Config file not found: {path}")
    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    suffix = data.get("student", {}).get("suffix", "")
    if not SUFFIX_PATTERN.match(str(suffix)):
        raise ValueError(
            f"student.suffix '{suffix}' is invalid. "
            "Must be lowercase, start with a letter, contain only [a-z0-9-], "
            "and be 2-31 chars long."
        )

    return _ns(data)


def as_dict(cfg: SimpleNamespace) -> dict:
    """Inverse of _ns — convert back to nested dict (for serialization)."""
    if isinstance(cfg, SimpleNamespace):
        return {k: as_dict(v) for k, v in vars(cfg).items()}
    if isinstance(cfg, list):
        return [as_dict(x) for x in cfg]
    return cfg
