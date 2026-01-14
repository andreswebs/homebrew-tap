# AI generated - this is a generic template for formulae that install binaries from GitHub

class GenericBinary < Formula
  desc "Generic binary installer from GitHub releases"
  homepage "https://github.com/OWNER/REPO"
  url "https://github.com/OWNER/REPO/releases/download/VERSION/BINARY_NAME-VERSION-OS-ARCH.tar.gz"
  license "LICENSE_TYPE"
  sha256 "SHA256_HASH_HERE"

  def install
    # For a simple binary installation
    bin.install "BINARY_NAME"

    # Alternative: if binary is in a subdirectory
    # bin.install "path/to/BINARY_NAME"

    # For installing additional files (documentation, configs, etc.)
    # doc.install "README.md", "CHANGELOG.md" if build.with? "docs"
    # etc.install "config.yaml" => "BINARY_NAME.yaml"
  end

  test do
    # Test that the binary was installed and is executable
    system "#{bin}/BINARY_NAME", "--version"

    # Alternative tests:
    # assert_match "expected_output", shell_output("#{bin}/BINARY_NAME --version")
    # system "#{bin}/BINARY_NAME", "--help"
  end
end
