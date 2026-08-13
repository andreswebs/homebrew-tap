cask "dnclient-desktop" do
  version "0.9.7,56c0d31f"
  sha256 "4cd697456f80e1bec1cb659d0fa8a35f4f1029e1b4bf8be2d8b7553e32d68506"

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
    "~/Library/Application Support/DNClient Desktop",
    "~/Library/Caches/net.defined.dnclient-desktop",
    "~/Library/HTTPStorages/net.defined.dnclient-desktop",
    "~/Library/Preferences/net.defined.dnclient-desktop.plist",
  ]
end
