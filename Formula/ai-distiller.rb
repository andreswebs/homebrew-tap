class AiDistiller < Formula
  desc "Ultra-fast tool for extracting essential APIs and structure from large codebases"
  homepage "https://github.com/janreges/ai-distiller"
  license "MIT"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/janreges/ai-distiller/releases/download/v1.3.1/aid-darwin-arm64-v1.3.1.tar.gz"
      sha256 "8b9701e95c453a87a029f3675df84e15331bc288145b9b90813837f967841273"
    else
      url "https://github.com/janreges/ai-distiller/releases/download/v1.3.1/aid-darwin-amd64-v1.3.1.tar.gz"
      sha256 "caeef230ffa1237a80b84e705c744a7a15dcc4849fdc29d939aaaaceb7d0f179"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/janreges/ai-distiller/releases/download/v1.3.1/aid-linux-arm64-v1.3.1.tar.gz"
      sha256 "03d3f1ccd1bc0b7b2fd1868874615dbd296078cd534b90ad2146b6944cd87663"
    else
      url "https://github.com/janreges/ai-distiller/releases/download/v1.3.1/aid-linux-amd64-v1.3.1.tar.gz"
      sha256 "7f0a2e2e30231fc06b7a544546478f748cc1b16a21073ea63866d88942be0dba"
    end
  end

  def install
    bin.install "aid"
  end

  def caveats
    <<~EOT
      AI Distiller (aid) is a tool for intelligently extracting essential APIs,
      types, and structure from large codebases.

      Supports 12+ programming languages and can compress 90-98% of code
      into AI-friendly context for development workflows.

      Author: Jan Reges (@janreges)
      Repository: https://github.com/janreges/ai-distiller
    EOT
  end

  test do
    system "#{bin}/aid", "--version"
  end
end
