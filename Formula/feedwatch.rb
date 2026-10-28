class Feedwatch < Formula
  desc "Agent-first command-line tool for watching RSS and Atom feeds"
  homepage "https://github.com/andreswebs/feedwatch"
  version "0.0.7"
  license "GPL-3.0-or-later"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-darwin-arm64-v#{version}.tar.gz"
      sha256 "4a87a5f854fc29773f827d6408a5d718eb70ad72c2d2637cd093ad106192b415"
    else
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-darwin-amd64-v#{version}.tar.gz"
      sha256 "0a05c2ff9c3ae3e720ed2e4e1d1cfa0703267e8cf795df4ef8986364e552764e"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-linux-arm64-v#{version}.tar.gz"
      sha256 "c0dc65ab729b0034c2dbcff26fe6e28f06128264909813786f878170facc3692"
    else
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-linux-amd64-v#{version}.tar.gz"
      sha256 "2c51c579d6be2c411e03358922196d943a5f915e6d0471d15371c04455682e16"
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
