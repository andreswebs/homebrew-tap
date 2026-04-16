class Gematria < Formula
  desc "Command-line tool for Hebrew gematria computation"
  homepage "https://github.com/andreswebs/gematria"
  version "0.0.1"
  license "GPL-3.0-or-later"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/gematria/releases/download/v#{version}/gematria-darwin-arm64-v#{version}.tar.gz"
      sha256 "500b995df8a55cd9457643f45680818ef4d5d69d425bdb7498bfb6d265bec0f7"
    else
      url "https://github.com/andreswebs/gematria/releases/download/v#{version}/gematria-darwin-amd64-v#{version}.tar.gz"
      sha256 "8de5a08884e7dfac503c6bd5ad27cf1390db64935440954cc07f257647c7aed4"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/andreswebs/gematria/releases/download/v#{version}/gematria-linux-arm64-v#{version}.tar.gz"
      sha256 "76c27c906e1f44217b5c8e2aa10aa3af6d1a0617b499087e838001c0a10b2553"
    else
      url "https://github.com/andreswebs/gematria/releases/download/v#{version}/gematria-linux-amd64-v#{version}.tar.gz"
      sha256 "f64869294790c29f80c9b8497f212a16921a35c2954e92de662c42ad66fac828"
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
