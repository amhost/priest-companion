# Public alpha release kit

Visible name: **Quest Companion**. Version: **0.2.0-alpha.1**. Repository: [amhost/priest-companion](https://github.com/amhost/priest-companion). The repository and installed folder retain their previous identity for continuity; user-facing titles and archive names are class-neutral.

## Release artifacts

- `QuestCompanion-0.2.0-alpha.1.zip`: installable folder `PriestCompanion/`, including its matching TOC, original source, license and documentation.
- `QuestCompanion-0.2.0-alpha.1-source.zip`: complete source, tests, build tools and documentation under `quest-companion/`.
- `SHA256SUMS.txt`: hashes for both ZIPs.
- `RELEASE-NOTES.md`: the public prerelease description.

Build from the reviewed source root with `python3 tools/build.py`. Run `python3 tools/check.py` before packaging. Publish tag `v0.2.0-alpha.1` on the exact reviewed commit, with GitHub's prerelease flag enabled. Attach the explicit installable ZIP in addition to the source archive. Compare uploaded sizes and SHA-256 digests before publishing.

This release builds on the separate UI branch. The incomplete dungeon prototype remains outside the package. The new bridge remains an alpha until the [fresh-login checklist](FRESH-LOGIN-CHECKLIST.md) has native results.

## Feedback

Collect the exact client build, Questie and QuestieDB versions, panel or tracker action, reproduction steps, expected/actual result, combat state and `/qc diagnostics`. Screenshots should show actual game behavior and omit private names/chat the tester does not want public. A mock or offline pass is not evidence of native rendering or secure execution.
