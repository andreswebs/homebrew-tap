class Terminology < Formula
  desc "CLI for agent-driven, terminology-focused academic translation"
  homepage "https://github.com/andreswebs/terminology"
  version "0.0.1"
  license "GPL-3.0-or-later"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/terminology/releases/download/v#{version}/terminology-darwin-arm64-v#{version}.tar.gz"
      sha256 "ae37f8eda77880550bfd4b64965d5afd94424b55c81666bb9eb2ee921203562e"
    else
      url "https://github.com/andreswebs/terminology/releases/download/v#{version}/terminology-darwin-amd64-v#{version}.tar.gz"
      sha256 "01b65b75895e64a2f983d4ac099ab78c96c7c777be607b071e5aa6cf6ff0dcd0"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/terminology/releases/download/v#{version}/terminology-linux-arm64-v#{version}.tar.gz"
      sha256 "a45c4c31e4e452feed49ca139b2ebd54d4dc30eca7196d69afb263480dbf2feb"
    else
      url "https://github.com/andreswebs/terminology/releases/download/v#{version}/terminology-linux-amd64-v#{version}.tar.gz"
      sha256 "203c01e1cd34f0cc135f181f1f57211fce9d33f08d2b9d5ac8f8d2992d0f3abc"
    end
  end

  def install
    bin.install "terminology"
  end

  def caveats
    <<~EOT
      terminology is a CLI for agent-driven, terminology-focused academic
      translation. It reads markdown source, enforces consistent terminology
      against a TBX-Linguist glossary, and exposes a small set of
      deterministic operations as subcommands.

      Author: Andre Silva (@andreswebs)
      Repository: https://github.com/andreswebs/terminology
    EOT
  end

  test do
    assert_match "\"version\":\"#{version}\"", shell_output("#{bin}/terminology --version")
  end
end
