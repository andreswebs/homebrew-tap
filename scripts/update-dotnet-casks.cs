#!/usr/bin/env dotnet run

using System.Runtime.CompilerServices;
using System.Text.RegularExpressions;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Security.Cryptography;

public class DotnetBuilds
{
    public partial class DotnetReleases
    {
        [JsonPropertyName("channel-version")]
        public string? ChannelVersion { get; set; }

        [JsonPropertyName("latest-release")]
        public string? LatestRelease { get; set; }

        [JsonPropertyName("latest-release-date")]
        public string? LatestReleaseDate { get; set; }

        [JsonPropertyName("latest-runtime")]
        public string? LatestRuntime { get; set; }

        [JsonPropertyName("latest-sdk")]
        public string? LatestSdk { get; set; }

        [JsonPropertyName("support-phase")]
        public string? SupportPhase { get; set; }

        [JsonPropertyName("release-type")]
        public string? ReleaseType { get; set; }

        [JsonPropertyName("releases")]
        public List<Release>? Releases { get; set; }
    }

    public partial class Release
    {
        [JsonPropertyName("release-date")]
        public string? ReleaseDate { get; set; }

        [JsonPropertyName("release-version")]
        public string? ReleaseVersion { get; set; }

        [JsonPropertyName("security")]
        public bool Security { get; set; }

        [JsonPropertyName("release-notes")]
        public Uri? ReleaseNotes { get; set; }

        [JsonPropertyName("runtime")]
        public Runtime? Runtime { get; set; }

        [JsonPropertyName("sdk")]
        public Sdk? Sdk { get; set; }
    }

    public partial class Runtime
    {
        [JsonPropertyName("version")]
        public string? Version { get; set; }

        [JsonPropertyName("version-display")]
        public string? VersionDisplay { get; set; }

        [JsonPropertyName("vs-version")]
        public string? VsVersion { get; set; }

        [JsonPropertyName("vs-mac-version")]
        public string? VsMacVersion { get; set; }

        [JsonPropertyName("files")]
        public List<File>? Files { get; set; }
    }

    public partial class File
    {
        [JsonPropertyName("name")]
        public string? Name { get; set; }

        [JsonPropertyName("rid")]
        public string? Rid { get; set; }

        [JsonPropertyName("url")]
        public Uri? Url { get; set; }

        [JsonPropertyName("hash")]
        public string? Hash { get; set; }
    }

    public partial class Sdk
    {
        [JsonPropertyName("version")]
        public string? Version { get; set; }

        [JsonPropertyName("version-display")]
        public string? VersionDisplay { get; set; }

        [JsonPropertyName("runtime-version")]
        public string? RuntimeVersion { get; set; }

        [JsonPropertyName("vs-version")]
        public string? VsVersion { get; set; }

        [JsonPropertyName("vs-mac-version")]
        public string? VsMacVersion { get; set; }

        [JsonPropertyName("vs-support")]
        public string? VsSupport { get; set; }

        [JsonPropertyName("vs-mac-support")]
        public string? VsMacSupport { get; set; }

        [JsonPropertyName("csharp-version")]
        public string? CsharpVersion { get; set; }

        [JsonPropertyName("fsharp-version")]
        public string? FsharpVersion { get; set; }

        [JsonPropertyName("vb-version")]
        public string? VbVersion { get; set; }

        [JsonPropertyName("files")]
        public List<File>? Files { get; set; }
    }
}

[JsonSerializable(typeof(DotnetBuilds.DotnetReleases))]
internal partial class DotnetBuildsJsonContext : JsonSerializerContext { }

public partial class RubyCaskUpdater
{
    public class CaskData
    {
        public required string Version { get; set; }
        public required string Sha256Arm { get; set; }
        public required string Sha256Intel { get; set; }
    }

    public static CaskData ReadCaskFile(string filePath)
    {
        if (!File.Exists(filePath))
            throw new FileNotFoundException($"Cask file not found: {filePath}");

        var content = File.ReadAllText(filePath);
        return ParseCaskContent(content);
    }

    public static CaskData ParseCaskContent(string content)
    {
        var versionMatch = VersionPattern().Match(content);
        var version = versionMatch.Success ? versionMatch.Groups[2].Value : "";

        var sha256Match = Sha256Pattern().Match(content);
        var sha256Arm = sha256Match.Success ? sha256Match.Groups[2].Value : "";
        var sha256Intel = sha256Match.Success ? sha256Match.Groups[4].Value : "";

        return new CaskData
        {
            Version = version,
            Sha256Arm = sha256Arm,
            Sha256Intel = sha256Intel,
        };
    }

    public static void UpdateCaskFile(string filePath, CaskData newData)
    {
        if (!File.Exists(filePath))
            throw new FileNotFoundException($"Cask file not found: {filePath}");

        var content = File.ReadAllText(filePath);
        var updatedContent = UpdateCaskContent(content, newData);
        File.WriteAllText(filePath, updatedContent);
    }

    public static string UpdateCaskContent(string content, CaskData newData)
    {
        if (!string.IsNullOrEmpty(newData.Version))
        {
            content = VersionPattern().Replace(content, "${1}" + newData.Version + "${3}");
        }

        if (!string.IsNullOrEmpty(newData.Sha256Arm) && !string.IsNullOrEmpty(newData.Sha256Intel))
        {
            content = Sha256Pattern().Replace(content, "${1}" + newData.Sha256Arm + "${3}" + newData.Sha256Intel + "${5}");
        }

        return content;
    }

    public static async Task<DotnetBuilds.DotnetReleases?> GetDotnetReleasesAsync(string url)
    {
        using var client = new HttpClient();

        try
        {
            var response = await client.GetAsync(url);
            response.EnsureSuccessStatusCode();
            var json = await response.Content.ReadAsStringAsync();
            var result = JsonSerializer.Deserialize(json, DotnetBuildsJsonContext.Default.DotnetReleases);
            return result;
        }
        catch (HttpRequestException ex)
        {
            Console.WriteLine($"HTTP Error: {ex.Message}");
            return null;
        }
        catch (JsonException ex)
        {
            Console.WriteLine($"JSON Error: {ex.Message}");
            return null;
        }
    }

    public static async Task<string> DownloadAndCalculateSha256Async(Uri fileUri)
    {
        ArgumentNullException.ThrowIfNull(fileUri);

        using var httpClient = new HttpClient();
        using var sha256 = SHA256.Create();
        httpClient.Timeout = TimeSpan.FromMinutes(5);

        using var response = await httpClient.GetAsync(fileUri, HttpCompletionOption.ResponseHeadersRead);
        response.EnsureSuccessStatusCode();

        using var stream = await response.Content.ReadAsStreamAsync();
        byte[] hashBytes = await sha256.ComputeHashAsync(stream);
        return Convert.ToHexStringLower(hashBytes);
    }

    const string DotnetArm64Filename = "dotnet-sdk-osx-arm64.pkg";
    const string DotnetX64Filename = "dotnet-sdk-osx-x64.pkg";

    // Resolve repo root from the script file's compile-time path (scripts/ -> repo root)
    static string GetRepoRoot([CallerFilePath] string scriptPath = "")
        => Path.GetDirectoryName(Path.GetDirectoryName(scriptPath))!;

    public static async Task Main(string[] args)
    {
        var repoRoot = GetRepoRoot();
        var supportedVersions = new List<string>
        {
            "10.0",
            "9.0",
            "8.0",
        };

        foreach (var version in supportedVersions)
        {
            try
            {
                Console.WriteLine($"Checking .NET {version}");
                var filePath = Path.Combine(repoRoot, "Casks", $"dotnet-sdk@{version}.rb");

                // Read current values
                var currentData = ReadCaskFile(filePath);

                Console.WriteLine($"Current version: {currentData.Version}");
                Console.WriteLine($"Current SHA256 ARM: {currentData.Sha256Arm}");
                Console.WriteLine($"Current SHA256 Intel: {currentData.Sha256Intel}");
                Console.WriteLine("");

                var dotnetRelease = await GetDotnetReleasesAsync($"https://builds.dotnet.microsoft.com/dotnet/release-metadata/{version}/releases.json");
                if (dotnetRelease == null || dotnetRelease.LatestSdk == null || currentData.Version == dotnetRelease.LatestSdk)
                {
                    Console.WriteLine($"No new release for .NET {version}");
                    Console.WriteLine("");
                    continue;
                }

                var latestSdkVersion = dotnetRelease.LatestSdk;
                Console.WriteLine($"New Release for .NET {version} is Available: {latestSdkVersion}");

                var sdkList = (dotnetRelease?.Releases?.First()?.Sdk) ?? throw new Exception("SDK is NULL");

                var arm64Release = sdkList.Files?.SingleOrDefault(x => x.Name == DotnetArm64Filename);
                if (arm64Release == null || arm64Release.Url == null)
                    throw new Exception($".NET {version}-arm64 URL not found");

                Console.WriteLine($"Calculating SHA-256 {arm64Release.Url}");
                var sha256arm64 = await DownloadAndCalculateSha256Async(arm64Release.Url);
                Console.WriteLine(sha256arm64);
                Console.WriteLine("");

                var x64Release = sdkList.Files?.SingleOrDefault(x => x.Name == DotnetX64Filename);
                if (x64Release == null || x64Release.Url == null)
                    throw new Exception($".NET {version}-x64 URL not found");

                Console.WriteLine($"Calculating SHA-256 {x64Release.Url}");
                var sha256x64 = await DownloadAndCalculateSha256Async(x64Release.Url);
                Console.WriteLine(sha256x64);
                Console.WriteLine("");

                // Update with new values
                var newData = new CaskData
                {
                    Version = latestSdkVersion, // New version
                    Sha256Arm = sha256arm64, // New ARM SHA256
                    Sha256Intel = sha256x64 // New Intel SHA256
                };

                // Update the file
                UpdateCaskFile(filePath, newData);
                Console.WriteLine($".NET {version} Cask file updated successfully!");
                Console.WriteLine("");

                // Verify the changes
                var updatedData = ReadCaskFile(filePath);
                Console.WriteLine($"Updated version: {updatedData.Version}");
                Console.WriteLine($"Updated SHA256 ARM: {updatedData.Sha256Arm}");
                Console.WriteLine($"Updated SHA256 Intel: {updatedData.Sha256Intel}");
                Console.WriteLine("");
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
        }
    }

  [GeneratedRegex(@"(version\s+"")([^""]+)("")")]
  private static partial Regex VersionPattern();
  [GeneratedRegex(@"(sha256\s+arm:\s+"")([^""]+)("",\s*intel:\s+"")([^""]+)("")")]
  private static partial Regex Sha256Pattern();
}
