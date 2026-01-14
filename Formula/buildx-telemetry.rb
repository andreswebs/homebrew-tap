class BuildxTelemetry < Formula
  desc "A tool for converting Docker Buildx logs to OpenTelemetry traces"
  homepage "https://github.com/sakajunquality/buildx-telemetry"
  url "https://github.com/sakajunquality/buildx-telemetry.git",
      tag:      "v0.0.1"
  license "MIT"
  head "https://github.com/sakajunquality/buildx-telemetry.git", branch: "main"

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X main.version=#{version}
      -X main.commit=#{tap.user}
      -X main.date=#{time.strftime("%Y-%m-%dT%H:%M:%SZ")}
    ]

    system "go", "build", *std_go_args(ldflags: ldflags), "./cmd"
  end

  def caveats
    <<~EOT
      Buildx Telemetry (buildx-telemetry) is a tool for converting Docker Buildx logs to OpenTelemetry traces.

      This application consumes Docker Buildx log output in the `rawjson` format and exports the build steps
      as OpenTelemetry traces. This allows you to view your Docker build steps in your favorite OpenTelemetry
      tracing visualization tool.

      Author: Jun Sakata (@sakajunquality)
      Repository: https://github.com/sakajunquality/buildx-telemetry
    EOT
  end

  test do
    output = shell_output("#{bin}/buildx-telemetry --v")
    assert_match "buildx-telemetry version", output
    assert_match version.to_s, output
  end
end
