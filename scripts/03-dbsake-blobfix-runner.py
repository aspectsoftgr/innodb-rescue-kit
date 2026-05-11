#!/usr/bin/env python3
r"""Wrapper around dbsake to work around frmdump crashes on BLOB/LONG_BLOB defaults.

Usage:
    python scripts/03-dbsake-blobfix-runner.py frmdump C:\path\to\table.frm

By default this assumes dbsake is stored at C:\tools\dbsake.
Override with the DBSAKE_ARCHIVE environment variable if needed.
"""

from __future__ import annotations

import os
import sys

DBSAKE_ARCHIVE = os.environ.get("DBSAKE_ARCHIVE", r"C:\tools\dbsake")
sys.path.insert(0, DBSAKE_ARCHIVE)

try:
    from dbsake.core.mysql.frm import mysqltypes  # type: ignore
except Exception as exc:  # pragma: no cover - depends on external dbsake archive
    print(f"Failed to import dbsake from {DBSAKE_ARCHIVE}: {exc}", file=sys.stderr)
    raise


def _blob_default_workaround(defaults, context):
    """Return a safe NULL-like default for BLOB metadata that dbsake cannot decode."""
    return None


for _name in (
    "unpack_type_blob",
    "unpack_type_tiny_blob",
    "unpack_type_medium_blob",
    "unpack_type_long_blob",
):
    if hasattr(mysqltypes, _name):
        setattr(mysqltypes, _name, _blob_default_workaround)

try:
    from dbsake.cli import main  # type: ignore  # noqa: E402
except Exception as exc:  # pragma: no cover
    print(f"Failed to import dbsake CLI from {DBSAKE_ARCHIVE}: {exc}", file=sys.stderr)
    raise

sys.argv[0] = DBSAKE_ARCHIVE
raise SystemExit(main())
