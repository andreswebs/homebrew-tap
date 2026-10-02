class Feedwatch < Formula
  desc "Agent-first command-line tool for watching RSS and Atom feeds"
  homepage "https://github.com/andreswebs/feedwatch"
  version "0.0.6"
  license "GPL-3.0-or-later"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-darwin-arm64-v#{version}.tar.gz"
      sha256 "8a8453b1c314c2a0b2db1162831ecd659106019152510cd00c751c91ce3a6a33"
    else
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-darwin-amd64-v#{version}.tar.gz"
      sha256 "9a3d88166e032338b3ad6a9078f1241662516ec606705fe9fbb548884101942e"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-linux-arm64-v#{version}.tar.gz"
      sha256 "5af4435f1915aea6ea663350deba372f444e429c1149b5af051711ea02e854a9"
    else
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-linux-amd64-v#{version}.tar.gz"
      sha256 "8b8a85cab0d532ff988662e7bf37994e7b17d5c93451a83ccc1ffdc00420e181"
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
