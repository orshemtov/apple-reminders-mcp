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
