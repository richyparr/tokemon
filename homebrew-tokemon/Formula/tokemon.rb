cask "tokemon" do
  version "1.0.0"
  sha256 "PLACEHOLDER_SHA256"

  url "https://github.com/AverageHelper/tokemon/releases/download/v#{version}/Tokemon-#{version}.dmg"
  name "Tokemon"
  desc "Monitor Claude Code usage from your macOS menu bar"
  homepage "https://tokemon.app"

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
