# AI generated - template for a no-op formula that only prints a message on install.
#
# Homebrew normally requires a url + sha256 and will refuse to install an empty keg.
# This template works around both by:
#   1. Overriding `fetch`, `verify_download_integrity`, and `stage` so nothing is
#      downloaded or extracted.
#   2. Writing a single marker file into `prefix` so the keg isn't empty.
#   3. Using `caveats` to print a message after `brew install` (and on `brew info`).

class Noop < Formula
  desc "No-op formula that prints a message and installs nothing"
  homepage "https://github.com/OWNER/REPO"
  url "about:blank"
  version "0.0.1"

  # Skip download, integrity check, and extraction — there's nothing to fetch.
  def fetch(*); end
  def verify_download_integrity(*); end
  def stage(*)
    yield if block_given?
  end

  def install
    # Homebrew refuses to link an empty keg, so drop a marker file.
    (prefix/"INSTALLED").write "This formula is a no-op.\n"
  end

  def caveats
    <<~EOS
      Hello from the no-op formula!

      This formula intentionally does nothing except print this message.
      Uninstall with:

        brew uninstall #{name}
    EOS
  end

  test do
    assert_predicate prefix/"INSTALLED", :exist?
  end
end
