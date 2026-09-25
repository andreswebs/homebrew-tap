class Codelens < Formula
  desc "Agent-first Go reimplementation of code-maat for evolutionary code analysis"
  homepage "https://github.com/andreswebs/codelens"
  version "0.0.5"
  license "GPL-3.0-or-later"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-darwin-arm64-v#{version}.tar.gz"
      sha256 "8b61b0680136b7a1c825ccb92b9df7007b92cd1330cfe082374d8567cdb54417"
    else
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-darwin-amd64-v#{version}.tar.gz"
      sha256 "a61a9c775c0ae7c73d863ae9507290fa3f21391ded772480a18dd525d680e069"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-linux-arm64-v#{version}.tar.gz"
      sha256 "949cdacd624096c2deec469f00263a112b89f85be89edb022e9339afa96987aa"
    else
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-linux-amd64-v#{version}.tar.gz"
      sha256 "1410a04ebd79d5e564b9cab94b9a1ca2d6b3b2abbde61b1bcb5e6ee97213cf17"
    end
  end

  def install
    bin.install "codelens"
  end

  def caveats
    <<~EOT
      codelens is an agent-first Go reimplementation of code-maat. It mines a
      git history log and runs evolutionary code analyses (coupling, hotspots,
      churn, ownership, code age, and more), emitting a structured JSON
      envelope. It is read-only: it never runs git, never writes files, and
      has no side effects.

      Author: Andre Silva (@andreswebs)
      Repository: https://github.com/andreswebs/codelens
    EOT
  end

  test do
    assert_match "\"version\":\"#{version}\"", shell_output("#{bin}/codelens --version")
  end
end
