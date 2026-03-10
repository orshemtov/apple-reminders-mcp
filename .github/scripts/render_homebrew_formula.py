#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", required=True)
    parser.add_argument("--sha256", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    formula = f'''class AppleRemindersMcp < Formula
  desc "MCP server for Apple Reminders on macOS"
  homepage "https://github.com/orshemtov/apple-reminders-mcp"
  url "{args.url}"
  sha256 "{args.sha256}"
  version "{args.version}"
  license "MIT"

  depends_on :macos

  def install
    bin.install "apple-reminders-mcp"
  end

  test do
    assert_match "Apple Reminders MCP", shell_output("#{{bin}}/apple-reminders-mcp --help")
  end
end
'''

    Path(args.output).write_text(formula, encoding="utf-8")


if __name__ == "__main__":
    main()
