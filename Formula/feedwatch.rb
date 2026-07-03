class Feedwatch < Formula
  desc "Agent-first command-line tool for watching RSS and Atom feeds"
  homepage "https://github.com/andreswebs/feedwatch"
  version "0.0.1"
  license "GPL-3.0-or-later"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-darwin-arm64-v#{version}.tar.gz"
      sha256 "4e4a329059789dde0435d0d411decf9929dd3c4a050d132cb5dd8eedc3150c1c"
    else
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-darwin-amd64-v#{version}.tar.gz"
      sha256 "1fdd0a6bd12a2ce16b3a343b95dde2f77a296cfe648537ca0e9ac97f8a80828f"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-linux-arm64-v#{version}.tar.gz"
      sha256 "7c1981d798da703962a435864974042d28359f950f695b68d1dc3e7a05e514e0"
    else
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-linux-amd64-v#{version}.tar.gz"
      sha256 "1a8f0e0a13e09cc1c17d25b8ab59250e6a2541fb722aeba304eed8de94fc9f10"
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
