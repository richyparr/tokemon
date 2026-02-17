cask "tokemon" do
  version "3.0.0"
  sha256 "f050ee85b8c7672874962f4b1bcee556e8e7d274701a6429f15122663d5399ab"

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
