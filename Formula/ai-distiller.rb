class AiDistiller < Formula
  desc "Ultra-fast tool for extracting essential APIs and structure from large codebases"
  homepage "https://github.com/janreges/ai-distiller"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/janreges/ai-distiller/releases/download/v1.5.0/aid-darwin-arm64-v1.5.0.tar.gz"
      sha256 "b58ad4194ae3f47468df86ac413fadebdd7735307d381a84dbbf7164051dbc8a"
    end
    on_intel do
      url "https://github.com/janreges/ai-distiller/releases/download/v1.5.0/aid-darwin-amd64-v1.5.0.tar.gz"
      sha256 "a902be9541dc422cd6f717e4a8ac2f4377114a3d3f4b0514446afc73b3e8d42e"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/janreges/ai-distiller/releases/download/v1.5.0/aid-linux-arm64-v1.5.0.tar.gz"
      sha256 "0a7c4fe536778b322aeadff04d4719d8baf6fa24aad56a058e1814d3ecc36c41"
    end
    on_intel do
      url "https://github.com/janreges/ai-distiller/releases/download/v1.5.0/aid-linux-amd64-v1.5.0.tar.gz"
      sha256 "e72b8c89545513389b8c97ab34c77fdfb006cbd701e7e4ba5bc397ed1bcb0908"
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
