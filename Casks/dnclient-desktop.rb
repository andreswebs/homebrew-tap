cask "dnclient-desktop" do
  version "0.9.5,764f2278"
  sha256 "d74ce6a7683e0ad7b96b842d0a8feaf4abefca6319ea9c352c95e16b9b0482fc"

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
