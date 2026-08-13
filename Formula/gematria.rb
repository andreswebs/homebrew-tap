class Gematria < Formula
  desc "Command-line tool for Hebrew gematria computation"
  homepage "https://github.com/andreswebs/gematria"
  version "0.0.2"
  license "GPL-3.0-or-later"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/gematria/releases/download/v#{version}/gematria-darwin-arm64-v#{version}.tar.gz"
      sha256 "391661eccb1000dc17082cafb0a73aebb5b6e83ddb84554fdfb6a58421600eb6"
    else
      url "https://github.com/andreswebs/gematria/releases/download/v#{version}/gematria-darwin-amd64-v#{version}.tar.gz"
      sha256 "b27dc4ba006d3e2e97dd3e7e82d0577771c6e6654bb34b5ea1081aac36d5bce2"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/gematria/releases/download/v#{version}/gematria-linux-arm64-v#{version}.tar.gz"
      sha256 "7a10c007001fc07dd6225b260d2c55a4a1bc13250c87325a93ffd6808daca09a"
    else
      url "https://github.com/andreswebs/gematria/releases/download/v#{version}/gematria-linux-amd64-v#{version}.tar.gz"
      sha256 "829cb437b961d843771aee16bb103dc44b954b9000fd67bc17cb965152a4cd81"
    end
  end

  def install
    bin.install "gematria"
  end

  def caveats
    <<~EOT
      gematria is a command-line tool for Hebrew gematria computation.
      Look up the numeric value of Hebrew letters and words across four
      classical systems (hechrachi, gadol, siduri, atbash), and find words
      matching a given value from a word list.

      Author: Andre Silva (@andreswebs)
      Repository: https://github.com/andreswebs/gematria
    EOT
  end

  test do
    assert_match "gematria v#{version}", shell_output("#{bin}/gematria --version")
    assert_match "\"version\":\"#{version}\"", shell_output("#{bin}/gematria --version --output json")
  end
end
