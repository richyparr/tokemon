cask "tokemon" do
  version "4.1.2"
  sha256 "92285c6aa756c8c674aae612f108acc3989f876888c78f8e50afd84b74059df8"

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
