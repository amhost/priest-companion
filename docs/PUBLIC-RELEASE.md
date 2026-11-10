# Public alpha release kit

The public name is **Priest Companion** and the first version is **0.1.0-alpha.1**. The public source repository is [amhost/priest-companion](https://github.com/amhost/priest-companion). Published packages belong on its [Releases page](https://github.com/amhost/priest-companion/releases).

## Prepared materials

- Installable addon ZIP with the correct top-level folder.
- Complete source ZIP, including tests and repeatable package tooling.
- README, changelog, MIT license, API notes and validation scope.
- `RELEASE-NOTES.md`, ready to paste as the public prerelease description.
- GitHub issue form for bug reports.
- SHA-256 checksum file for both archives.

The alpha description explicitly says that native Forever testing is pending. Do not present the offline test results as game compatibility. When in-game results arrive, update the validation record with the exact client build and observed outcomes.

## Release destination: GitHub Releases

GitHub supports release notes, downloadable attached files and an explicit prerelease designation. Publish the alpha under `amhost/priest-companion`, with the installable archive attached separately from GitHub's generated source archives.

The [current GitHub release instructions](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) describe this workflow:

1. Open the repository's main page and choose **Releases > Draft a new release**.
2. Under **Choose a tag**, create `v0.1.0-alpha.1` on the commit containing this source.
3. Set the title to **Priest Companion 0.1.0-alpha.1**.
4. Paste the complete contents of `RELEASE-NOTES.md`.
5. Attach `PriestCompanion-0.1.0-alpha.1.zip` and `SHA256SUMS.txt`. The source ZIP can also be attached for convenience.
6. Select **Set as a pre-release**. Review the files and description before publishing.

No download-manager installation is required for someone using the attached addon ZIP. An addon directory such as Wago can be an additional discovery channel once its project identity and supported game-version options have been selected.

## Initial feedback to collect

Ask testers for the exact client version/build, the panel involved, short reproduction steps, expected/actual behavior, whether combat was active, and the `/pc diagnostics` report. A real in-game screenshot is useful after removing names or chat the tester does not want public. Do not use a mock image as proof of native rendering.
