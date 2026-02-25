cask "tokemon" do
  version "3.0.12"
  sha256 "7ffd042af8483dd60a021b61a4c5bf34ee0709cf1002eaf91feff45fc91cc958"

  url "https://github.com/richyparr/tokemon/releases/download/v#{version}/Tokemon.zip"
  name "Tokemon"
  desc "Monitor your Claude usage from the macOS menu bar"
  homepage "https://tokemon.ai"

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
