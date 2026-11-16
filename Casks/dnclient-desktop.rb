cask "dnclient-desktop" do
  version "1.0.0,837870e1"
  sha256 "ce1242b9ac167bca4c0e6dc76c8c008d0e10d389fbaec7ae444a558aacc9d370"

  url "https://dl.defined.net/#{version.csv.second}/v#{version.csv.first}/macos/DNClient-Desktop.dmg"
  name "DNClient Desktop"
  desc "Client for the Defined Networking managed Nebula overlay network"
  homepage "https://www.defined.net/"

  livecheck do
    url "https://api.defined.net/v1/downloads"
    strategy :json do |json|
      download_url = json.dig("data", "dnclient", "latest", "macos-universal-desktop")
      match = download_url&.match(%r{/(\h+)/v(\d+(?:\.\d+)+)/})
      next if match.nil?

      "#{match[2]},#{match[1]}"
    end
  end

  depends_on macos: :ventura

  app "DNClient Desktop.app"

  uninstall launchctl: "net.defined.dnclientd",
            quit:      "net.defined.dnclient-desktop"

  zap trash: [
    "/Library/Application Support/DefinedNet",
    "~/Library/Application Support/DNClient Desktop",
    "~/Library/Caches/dnclient-desktop",
    "~/Library/Caches/net.defined.dnclient-desktop",
    "~/Library/HTTPStorages/net.defined.dnclient-desktop",
    "~/Library/Preferences/dnclient-desktop.plist",
    "~/Library/Preferences/net.defined.dnclient-desktop.plist",
    "~/Library/WebKit/dnclient-desktop",
    "~/Library/WebKit/net.defined.dnclient-desktop",
  ]
end
