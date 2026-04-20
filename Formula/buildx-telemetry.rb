# No-op formula — buildx-telemetry was removed from this tap.
# Kept as a no-op so existing users get a clear message on reinstall/upgrade.
# Based on the template in misc/noop.rb.

class BuildxTelemetry < Formula
  desc "No-op placeholder — buildx-telemetry has been removed from this tap"
  homepage "https://github.com/andreswebs/homebrew-tap"
  url "about:blank"
  version "0.0.2"

  # Skip download, integrity check, and extraction — there's nothing to fetch.
  def fetch(*); end
  def verify_download_integrity(*); end
  def stage(*)
    yield if block_given?
  end

  def install
    # Homebrew refuses to link an empty keg, so drop a marker file.
    (prefix/"REMOVED").write "buildx-telemetry was removed from this tap.\n"
  end

  def caveats
    <<~EOS
      buildx-telemetry has been removed from this tap and is no longer maintained here.

      This formula is now a no-op placeholder. You can uninstall it with:

        brew uninstall #{name}
    EOS
  end

  test do
    assert_predicate prefix/"REMOVED", :exist?
  end
end
