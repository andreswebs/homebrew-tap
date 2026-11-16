# Template for a formula that installs a prebuilt binary from GitHub releases.
# Copy it to Formula/<name>.rb, rename the class to match the file name and
# replace OWNER, REPO and BINARY_NAME. The update script reads the repository,
# the version and the asset names from the url lines, and rewrites the version
# in them and the checksums from the latest release. There is no version line:
# brew audit rejects one that only repeats the version in the url.

class GenericBinary < Formula
  desc "One-line description that does not start with an article"
  homepage "https://github.com/OWNER/REPO"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/OWNER/REPO/releases/download/v0.0.0/BINARY_NAME-darwin-arm64-v0.0.0.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
    on_intel do
      url "https://github.com/OWNER/REPO/releases/download/v0.0.0/BINARY_NAME-darwin-amd64-v0.0.0.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/OWNER/REPO/releases/download/v0.0.0/BINARY_NAME-linux-arm64-v0.0.0.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
    on_intel do
      url "https://github.com/OWNER/REPO/releases/download/v0.0.0/BINARY_NAME-linux-amd64-v0.0.0.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end

  def install
    bin.install "BINARY_NAME"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/BINARY_NAME --version")
  end
end
