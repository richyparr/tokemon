cask "tokemon" do
  version "4.1.10"
  sha256 "e9a6edd5a96d46e02769cdc8d4acec02606cf415539eb15dc3ecdb4ab7338fcb"

  url "https://github.com/richyparr/tokemon/releases/download/v#{version}/Tokemon.zip",
      verified: "github.com/richyparr/tokemon/"
  name "Tokemon"
  desc "Monitor your Claude usage from the macOS menu bar"
  homepage "https://tokemon.ai"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :tahoe"

  app "Tokemon.app"

  zap trash: [
    "~/Library/Preferences/ai.tokemon.app.plist",
    "~/.tokemon",
  ]
end
