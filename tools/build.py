#!/usr/bin/env python3
"""Validate manifest integrity and create reproducible release/source archives."""
from __future__ import annotations
import hashlib
from pathlib import Path
import re
import shutil
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "PriestCompanion"
OUTPUT = ROOT / "dist"
manifest = (ADDON / "PriestCompanion.toc").read_text(encoding="utf-8")
version = re.search(r"^## Version: ([0-9A-Za-z.+-]+)$", manifest, re.M).group(1)
assert "## Interface: 16001" in manifest
required_docs = ["README.md", "LICENSE", "CHANGELOG.md", "RELEASE-NOTES.md"]
for name in required_docs:
    assert (ROOT / name).is_file(), name

# The installable folder carries its own instructions and license.
for name in required_docs:
    shutil.copyfile(ROOT / name, ADDON / name)
(ADDON / "docs").mkdir(exist_ok=True)
for path in (ROOT / "docs").glob("*.md"):
    shutil.copyfile(path, ADDON / "docs" / path.name)

entries = []
for line in manifest.splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    relative = Path(line.replace("\\", "/"))
    assert not relative.is_absolute() and ".." not in relative.parts, line
    target = ADDON / relative
    assert target.is_file(), f"Missing manifest entry: {line}"
    for parent, part in zip([ADDON, *[ADDON.joinpath(*relative.parts[:i]) for i in range(1, len(relative.parts))]], relative.parts):
        assert part in [p.name for p in parent.iterdir()], f"Case mismatch: {line}"
    target.read_text(encoding="utf-8")
    if target.suffix == ".xml":
        ET.parse(target)
    entries.append(relative.as_posix())
assert len(entries) == len(set(entries)), "Duplicate manifest entry"
assert "Core.lua" == entries[0]
assert entries.index("UI.lua") < entries.index("Modules/Resources.lua")
assert entries.index("QuestieBridge.lua") < entries.index("Modules/Quests.lua")
assert not (ADDON / "Modules" / "Priest.lua").exists(), "Remove the obsolete spell editor before packaging"

OUTPUT.mkdir(exist_ok=True)
def archive(path, files, base, prefix):
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as output:
        for file in sorted(files):
            name = prefix + file.relative_to(base).as_posix()
            item = zipfile.ZipInfo(name, date_time=(2026, 11, 14, 0, 0, 0))
            item.compress_type = zipfile.ZIP_DEFLATED
            item.external_attr = 0o100644 << 16
            output.writestr(item, file.read_bytes())
    with zipfile.ZipFile(path) as check:
        assert check.testzip() is None
        assert all(name.startswith(prefix) and "/../" not in name for name in check.namelist())

release = OUTPUT / f"QuestCompanion-{version}.zip"
source = OUTPUT / f"QuestCompanion-{version}-source.zip"
archive(release, [p for p in ADDON.rglob("*") if p.is_file()], ROOT, "")
with zipfile.ZipFile(release) as check:
    assert "PriestCompanion/PriestCompanion.toc" in check.namelist()
    assert all(name.startswith("PriestCompanion/") for name in check.namelist())
source_files = [p for p in ROOT.rglob("*") if p.is_file()
                and "dist" not in p.relative_to(ROOT).parts
                and "__pycache__" not in p.relative_to(ROOT).parts
                and ".git" not in p.relative_to(ROOT).parts]
archive(source, source_files, ROOT, "quest-companion/")
checksums=[]
for path in (release,source):
    digest=hashlib.sha256(path.read_bytes()).hexdigest()
    checksums.append(f"{digest}  {path.name}")
    print(f"{path.name}: {path.stat().st_size} bytes; SHA-256 {digest}")
(OUTPUT / "SHA256SUMS.txt").write_text("\n".join(checksums)+"\n",encoding="ascii")
print(f"PASS: {len(entries)} manifest entries, XML, UTF-8, ZIP integrity, paths and checksums")
