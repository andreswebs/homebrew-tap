class Feedwatch < Formula
  desc "Agent-first command-line tool for watching RSS and Atom feeds"
  homepage "https://github.com/andreswebs/feedwatch"
  version "0.0.4"
  license "GPL-3.0-or-later"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-darwin-arm64-v#{version}.tar.gz"
      sha256 "e4e5aca28acd78ef6eb3bb838f61d0a910e862b50f99c3d4f0ca37d7d320adc9"
    else
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-darwin-amd64-v#{version}.tar.gz"
      sha256 "4674b53c49c35ff89b5d46a9e95c2b461ca46c7bc8a609c46521f54d161e854b"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-linux-arm64-v#{version}.tar.gz"
      sha256 "cd0f74bbd43b479ac5a0827d1d3bdbc8fbf6bc09adc71ddd9f47cde5c5b31e16"
    else
      url "https://github.com/andreswebs/feedwatch/releases/download/v#{version}/feedwatch-linux-amd64-v#{version}.tar.gz"
      sha256 "97fabe35b99024fd0357b50fb1c21d58cf3928ed543c0bf94d82a543051dabc0"
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
