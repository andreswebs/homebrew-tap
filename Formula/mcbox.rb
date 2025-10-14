class Mcbox < Formula
  desc "A pluggable MCP server in Bash and jq"
  homepage "https://andreswebs.github.io/mcbox"
  url "https://github.com/andreswebs/mcbox/releases/download/0.1.6/mcbox-0.1.6.tar.gz"
  sha256 "bd55b61834e586dd4684652808f575000730df4948b5096fea5f297e99e7039c"
  license "GPL-3.0-or-later"

  depends_on "bash"
  depends_on "jq"
  depends_on "coreutils"

  def install
    libexec.install "mcbox-core.bash"
    libexec.install "mcbox-server.bash"
    libexec.install "version.json"

    (libexec/"defaults").install Dir["defaults/*"]

    (bin/"mcbox").write <<~EOF
      #!/usr/bin/env bash
      bin_dir="/bin"
      gnubin_dir="#{HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin"
      IFS=':' read -r -a path_array <<< "${PATH}"
      gnubin=false
      for dir in "${path_array[@]}"; do
          if [ "${dir}" == "${bin_dir}" ]; then
              break
          fi
          if [ "${dir}" == "${gnubin_dir}" ]; then
              gnubin=true
              break
          fi
      done
      if ! ${gnubin}; then
          export PATH="${gnubin_dir}:${PATH}"
      fi
      export MCBOX_DATA_HOME="#{libexec}"
      exec "#{libexec}/mcbox-server.bash" "${@}"
    EOF
  end

  test do
    output = shell_output("#{bin}/mcbox --version")
    assert_match(/^mcbox/, output.strip)
  end
end
