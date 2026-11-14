# Public alpha release kit

Visible name: **Quest Companion**. Version: **0.2.0-alpha.3**. Repository: [amhost/priest-companion](https://github.com/amhost/priest-companion). The repository and installed folder retain their previous identity for continuity; user-facing titles and archive names are class-neutral.

## Release artifacts

- `QuestCompanion-0.2.0-alpha.3.zip`: installable folder `PriestCompanion/`, with its matching TOC, original source, license and documentation.
- `QuestCompanion-0.2.0-alpha.3-source.zip`: complete source, tests, build tools and documentation under `quest-companion/`.
- `SHA256SUMS.txt`: hashes for both ZIPs.
- `RELEASE-NOTES.md`: the public prerelease description.

From the reviewed source root, run these commands in Bash:

```bash
python3 tools/check.py
git diff --check
python3 tools/build.py
```

Publish tag `v0.2.0-alpha.3` on the exact reviewed commit, with GitHub's prerelease flag enabled. Attach the explicit installable ZIP in addition to the complete source ZIP. Compare uploaded sizes and SHA-256 digests before publishing, then verify the tag points to the reviewed commit.

This hotfix builds on `feature/native-guide` at `a1affef80cf2aab07ff54292ff200f33b1407608`. The new working branch is `fix/questie-timer-callback`. It removes the Questie timer-callback hook implicated in the user's alpha.2 reload failure. Native alpha.3 reload validation remains pending. See the [fresh-login checklist](FRESH-LOGIN-CHECKLIST.md).

## Feedback

Collect the exact client build, Questie and QuestieDB versions, panel or tracker action, selected guide action, reproduction steps, expected/actual result, combat state and `/qc diagnostics`. Screenshots should show actual game behavior and omit private names/chat the tester does not want public. A mock or offline pass is not evidence of native rendering or secure execution.
