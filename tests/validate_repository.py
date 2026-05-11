from __future__ import annotations

import pathlib
import py_compile
import re
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
failures: list[str] = []

def read(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore")

# Python compile check. Compile into a temporary directory so validation does not
# create __pycache__ files inside the repository.
with tempfile.TemporaryDirectory() as cache_dir:
    cache_root = pathlib.Path(cache_dir)
    for py in ROOT.rglob("*.py"):
        try:
            rel = py.relative_to(ROOT)
            cfile = cache_root / rel.with_suffix(".pyc")
            cfile.parent.mkdir(parents=True, exist_ok=True)
            py_compile.compile(str(py), cfile=str(cfile), doraise=True)
        except Exception as exc:
            failures.append(f"Python compile failed: {py}: {exc}")

# Markdown fence balance
for md in ROOT.rglob("*.md"):
    text = read(md)
    if text.count("```") % 2 != 0:
        failures.append(f"Unbalanced fenced code blocks: {md}")

# PowerShell sanity checks that do not require pwsh
for ps1 in (ROOT / "scripts").glob("*.ps1"):
    text = read(ps1)

    if "\t" in text:
        failures.append(f"Tab character found in {ps1}")

    uncommented = "\n".join(line for line in text.splitlines() if not line.lstrip().startswith("#"))
    if re.search(r"\$host\b", uncommented, flags=re.IGNORECASE):
        failures.append(f"Use of $host variable found; PowerShell $Host is read-only: {ps1}")

    opens = len(re.findall(r"(?m)@['\"]\s*$", text))
    closes = len(re.findall(r"(?m)^\s*['\"]@\s*$", text))
    if opens != closes:
        failures.append(f"Possible unbalanced here-string delimiters in {ps1}: opens={opens}, closes={closes}")

    if re.search(r"(?m)^\s*['\"]@\s*\|", text):
        failures.append(f"Here-string close piped on same line in {ps1}")

    if ps1.name != "00-config-template.ps1" and "param(" not in text:
        failures.append(f"PowerShell script missing param block: {ps1}")

# Genericity check: scan repo content except this validator file.
forbidden = [
    "ahp_saas",
    "elecreator",
    "merchantdb",
    "communitydb",
    "aspectpal_local",
    "wp_fntxz",
    "acme_commerce",
]
for path in ROOT.rglob("*"):
    if path == pathlib.Path(__file__).resolve():
        continue
    if path.is_file() and path.suffix.lower() in {".md", ".ps1", ".py", ".json", ".txt", ".ini", ".yml", ".yaml"}:
        text = read(path).lower()
        for word in forbidden:
            if word in text:
                failures.append(f"Incident-specific name '{word}' found in {path}")

# Generated Python bytecode should never be committed or shipped.
for path in ROOT.rglob("*"):
    if "__pycache__" in path.parts or path.suffix.lower() in {".pyc", ".pyo"}:
        failures.append(f"Generated Python cache file should not be included: {path}")

required = [
    "README.md",
    "LICENSE",
    "DISCLAIMER.md",
    "SECURITY.md",
    "CONTRIBUTING.md",
    "docs/01-triage-and-safety.md",
    "docs/04-single-table-recovery.md",
    "scripts/04-recover-orphaned-ibd-tables.ps1",
    ".github/workflows/validate.yml",
]
for rel in required:
    if not (ROOT / rel).exists():
        failures.append(f"Required repository file missing: {rel}")

if failures:
    print("\n".join(failures))
    sys.exit(1)

print("Repository validation checks passed.")
