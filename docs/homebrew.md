# Homebrew Automation

This repository publishes release binaries from `.github/workflows/release.yml` and then updates the Homebrew tap automatically.

## What Happens On Each Tag

When you push a tag like `v0.1.3`:

1. GitHub Actions builds the macOS release binary.
2. The workflow uploads `apple-reminders-mcp-<version>-macos-arm64.tar.gz` to the GitHub Release.
3. The workflow checks out `orshemtov/homebrew-brew`.
4. It rewrites `Formula/apple-reminders-mcp.rb` with the new release URL and SHA256.
5. It commits and pushes the formula bump to the tap repository.

After that, users can run:

```bash
brew update
brew upgrade apple-reminders-mcp
```

## Required Secret

Add this repository secret in `orshemtov/apple-reminders-mcp`:

- `HOMEBREW_TAP_GITHUB_TOKEN`

The token should be a GitHub personal access token that can push to `orshemtov/homebrew-brew`.

Recommended permissions:

- Contents: Read and write

## Notes

- `GITHUB_TOKEN` is used for creating or updating the release in this repository.
- `HOMEBREW_TAP_GITHUB_TOKEN` is used only for pushing the formula update to the tap repo.
- Homebrew users still need to run `brew update` and `brew upgrade`; installs do not auto-upgrade in the background.
