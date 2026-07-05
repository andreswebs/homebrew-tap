class Feedwatch < Formula
  desc "Agent-first command-line tool for watching RSS and Atom feeds"
  homepage "https://github.com/andreswebs/feedwatch"
  version "0.0.2"
  license "GPL-3.0-or-later"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-darwin-arm64-v#{version}.tar.gz"
      sha256 "ffe595cf0aebd06287407b0462548c4caa2dd37c1ede264ef248156cdb89796f"
    else
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-darwin-amd64-v#{version}.tar.gz"
      sha256 "17add38d49a0536dd1254e449998534c6f568f47296e0eb79ca88976352bbbba"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-linux-arm64-v#{version}.tar.gz"
      sha256 "506bb2a66672d1aa6c9368698cba3f15265afa24667b1d09f14a4b70e0795551"
    else
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-linux-amd64-v#{version}.tar.gz"
      sha256 "02ac7789ea36d9b9d5dd78e4f8a385095f7ab0447100e31fbbe00b49b8d44276"
    end
  end

  def install
    bin.install "feedwatch"
  end

  def caveats
    <<~EOT
      feedwatch is an agent-first command-line tool for watching RSS and Atom
      feeds. It fetches, parses, normalizes, stores, deduplicates, and queries
      feed items, emitting structured JSON for consumption by an AI agent.

      Author: Andre Silva (@andreswebs)
      Repository: https://github.com/andreswebs/feedwatch
    EOT
  end

  test do
    assert_match "\"version\":\"#{version}\"", shell_output("#{bin}/feedwatch --version")
  end
end
