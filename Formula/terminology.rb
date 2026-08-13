class Terminology < Formula
  desc "CLI for agent-driven, terminology-focused academic translation"
  homepage "https://github.com/andreswebs/terminology"
  version "0.0.2"
  license "GPL-3.0-or-later"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/terminology/releases/download/v#{version}/terminology-darwin-arm64-v#{version}.tar.gz"
      sha256 "f13c94bcaa49847b463263f5b1cd6beda15ca7aa05bbbff3cd12cd28ff229765"
    else
      url "https://github.com/andreswebs/terminology/releases/download/v#{version}/terminology-darwin-amd64-v#{version}.tar.gz"
      sha256 "ca18bbf0c36e501a9410a575dbc43a606456352f5e881f4d8d94f667df244b8a"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/terminology/releases/download/v#{version}/terminology-linux-arm64-v#{version}.tar.gz"
      sha256 "6f59369e8c7cad190f6071e631b6a615caf32f5f34e2a29f2540aecb5797578b"
    else
      url "https://github.com/andreswebs/terminology/releases/download/v#{version}/terminology-linux-amd64-v#{version}.tar.gz"
      sha256 "1440aaab2d5600aa5cbb0338c4673e9e997c3a47ff907edf34b3368ec64f3184"
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
