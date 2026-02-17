cask "tokemon" do
  version "3.0.3"
  sha256 "43690ea57ce991f6cdf704f905260d092f36a0c2011f249bfc295765c002fee7"

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
