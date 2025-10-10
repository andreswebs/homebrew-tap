class Mcbox < Formula
  desc "A pluggable MCP server in Bash and jq"
  homepage "https://andreswebs.github.io/mcbox"
  url "https://github.com/andreswebs/mcbox/releases/download/0.1.4/mcbox-0.1.4.tar.gz"
  sha256 "7f6cb70cf51db377f780c95dc98983e45204c057dd57e313dd9bb4e99084419c"
  license "GPL-3.0-or-later"

  depends_on "bash"
  depends_on "jq"

  def install
    libexec.install "mcbox-core.bash"
    libexec.install "mcbox-server.bash"
    libexec.install "version.json"

    (libexec/"defaults").install Dir["defaults/*"]

    (bin/"mcbox").write <<~EOF
      #!/usr/bin/env bash
      export MCBOX_DATA_HOME="#{libexec}"
      exec "#{libexec}/mcbox-server.bash" "${@}"
    EOF
  end

  test do
    output = shell_output("#{bin}/mcbox --version")
    assert_match(/^mcbox/, output.strip)
  end
end
