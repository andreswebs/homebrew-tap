class Codelens < Formula
  desc "Agent-first Go reimplementation of code-maat for evolutionary code analysis"
  homepage "https://github.com/andreswebs/codelens"
  version "0.0.1"
  license "GPL-3.0-or-later"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-darwin-arm64-v#{version}.tar.gz"
      sha256 "30e930f373ee9231314a03d7b9b0a9816fdc23e180cd9d7b90f664abb681423d"
    else
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-darwin-amd64-v#{version}.tar.gz"
      sha256 "87b93f93583be4a3b53569ce9876b85f9d9c708803c038b7a737b4f4eb2736ae"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-linux-arm64-v#{version}.tar.gz"
      sha256 "6b37a3886ca3bc302163ff3233cab0e185a4d7c21b4adaf09a91885d3973958a"
    else
      url "https://github.com/andreswebs/codelens/releases/download/v#{version}/codelens-linux-amd64-v#{version}.tar.gz"
      sha256 "6cd185f268b37e3ccce09aed46ceede71db1d413c00d146aedf45584297e1f4d"
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
