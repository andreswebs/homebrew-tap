class Codelens < Formula
  desc "Agent-first Go reimplementation of code-maat for evolutionary code analysis"
  homepage "https://github.com/andreswebs/codelens"
  version "0.0.2"
  license "GPL-3.0-or-later"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-darwin-arm64-v#{version}.tar.gz"
      sha256 "802471cd5465824f18912924b9ca1e04da412f23ea6c92b9958e2b0f38b5e211"
    else
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-darwin-amd64-v#{version}.tar.gz"
      sha256 "a482eaaadb462807b1436d07d2628f019fb034f1c2fc31274959a0f0d79bb447"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-linux-arm64-v#{version}.tar.gz"
      sha256 "64d0e031bf9f0e99798f192bc5003eb126e46c206c920369a58ecf6873914c65"
    else
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-linux-amd64-v#{version}.tar.gz"
      sha256 "587faaca205e49c25c4426994c4e6373f2005a2c5010f27ff82066d697df9fa2"
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
