class Codelens < Formula
  desc "Agent-first Go reimplementation of code-maat for evolutionary code analysis"
  homepage "https://github.com/andreswebs/codelens"
  version "0.0.3"
  license "GPL-3.0-or-later"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-darwin-arm64-v#{version}.tar.gz"
      sha256 "dfeba91ca16372b56f8c6b37edb760469fd1aa6381335bc009b361ff9fc0e74c"
    else
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-darwin-amd64-v#{version}.tar.gz"
      sha256 "a7939e6aed4d88f4222dbda113a6d137066d3f89351a4cc7448dabf7bd2d7745"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-linux-arm64-v#{version}.tar.gz"
      sha256 "d25190c96088dfd33bef739b321519c8e3fb5f1f54229dfa1a9fbe387d44a003"
    else
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-linux-amd64-v#{version}.tar.gz"
      sha256 "5b5c4d58aca4b8f145196a8f97188f1f6e3f862c6b93defd950b1051931ae23b"
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
