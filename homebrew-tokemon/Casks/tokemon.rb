cask "tokemon" do
  version "4.1.0"
  sha256 "35af4a8ef5cd0864ca34dc49ae9c4cb73cf031b716c0cd698c894842a89a2434"

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
