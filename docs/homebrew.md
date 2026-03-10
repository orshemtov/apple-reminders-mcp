# Homebrew Release Guide

This project is distributed through the `orshemtov/brew` tap.

## Prerequisites

- A public GitHub repo for this project at `orshemtov/apple-reminders-mcp`
- Homebrew installed locally
- GitHub CLI installed and authenticated with an account that can create repositories and releases
- A tagged release in this repo, such as `v0.1.0`

## Runtime Notes

- `apple-reminders-mcp` is a local macOS executable, not a hosted service.
- It uses the Reminders database of the Mac where it runs.
- The Reminders app does not need to remain open.
- The local user must grant Reminders permission to the terminal, host app, or installed executable that launches the server.
- If permission was previously denied, re-enable it in `System Settings > Privacy & Security > Reminders`.

## One-Time Tap Setup

Create the tap locally:

```bash
brew tap-new orshemtov/homebrew-brew
```

Publish it to GitHub:

```bash
gh repo create orshemtov/homebrew-brew --public --source "$(brew --repository orshemtov/homebrew-brew)" --push
```

Homebrew will expose this repository to users as the tap name `orshemtov/brew`.

## Release Workflow In This Repo

When you push a tag like `v0.1.0`, `.github/workflows/release.yml` will:

- build the release binary on `macos-14`
- create `apple-reminders-mcp-0.1.0-macos-arm64.tar.gz`
- generate a matching `.sha256` file
- create a GitHub Release and upload both files

## First Release Steps

1. Push the code to GitHub.
2. Create and push the first tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

3. Wait for the Release workflow to finish.
4. Open the GitHub Release and copy the SHA256 value from the uploaded `.sha256` file.
5. Use `docs/homebrew-formula-template.rb` as the starting point for the formula.

## Formula Setup In The Tap

In the `orshemtov/homebrew-brew` repository, create:

`Formula/apple-reminders-mcp.rb`

Template:

```ruby
class AppleRemindersMcp < Formula
  desc "MCP server for Apple Reminders on macOS"
  homepage "https://github.com/orshemtov/apple-reminders-mcp"
  url "https://github.com/orshemtov/apple-reminders-mcp/releases/download/v0.1.0/apple-reminders-mcp-0.1.0-macos-arm64.tar.gz"
  sha256 "REPLACE_WITH_RELEASE_SHA256"
  license "MIT"

  depends_on :macos

  def install
    bin.install "apple-reminders-mcp"
  end

  test do
    assert_match "Apple Reminders MCP", shell_output("#{bin}/apple-reminders-mcp --help")
  end
end
```

Replace:

- the `url` with the actual release asset URL
- the `sha256` with the actual release hash

Then commit and push the formula in the tap repo.

## Local Verification

Test the formula locally before announcing it:

```bash
brew install orshemtov/brew/apple-reminders-mcp
apple-reminders-mcp --help
apple-reminders-mcp --version
```

If you need to reinstall during testing:

```bash
brew uninstall apple-reminders-mcp
brew untap orshemtov/brew
brew install orshemtov/brew/apple-reminders-mcp
```

## User Install Command

Once the tap and formula are published, users install with:

```bash
brew install orshemtov/brew/apple-reminders-mcp
```

## Updating For Later Releases

For each new version:

1. Tag and push a new release like `v0.1.1`.
2. Wait for the GitHub Release assets to upload.
3. Update the formula `url` and `sha256` in the tap repo.
4. Commit and push the tap change.
5. Users upgrade with `brew upgrade`.
