cask "tokemon" do
  version "4.0.3"
  sha256 "330a38db7c95c99168d3627f3c656ecb3bdb8c5dd84569d78507fa4abc4332ac"

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
