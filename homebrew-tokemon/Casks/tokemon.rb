cask "tokemon" do
  version "3.0.1"
  sha256 "79faefb3c42bd94c8135831491a1000cf94fe81e2920831b5cc4d00b06645a28"

  url "https://github.com/richyparr/tokemon/releases/download/v#{version}/Tokemon-#{version}.dmg"
  name "Tokemon"
  desc "Monitor Claude Code usage from your macOS menu bar"
  homepage "https://github.com/richyparr/tokemon"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "Tokemon.app"

  zap trash: [
    "~/Library/Preferences/ai.tokemon.app.plist",
    "~/.tokemon",
  ]
end
