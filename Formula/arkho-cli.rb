require "download_strategy"

# Download a release asset from a PRIVATE GitHub repo using HOMEBREW_GITHUB_API_TOKEN.
# arkho-cli is a private repo, so the plain release-download URL is not reachable without auth;
# this resolves the asset id via the API and downloads it with the token.
class GitHubPrivateReleaseDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    super
    match = url.match(%r{https://github\.com/([^/]+)/([^/]+)/releases/download/([^/]+)/(.+)})
    raise CurlDownloadStrategyError, "Invalid GitHub release URL: #{url}" unless match

    _, @owner, @repo, @tag, @filename = *match
    @token = ENV["HOMEBREW_GITHUB_API_TOKEN"]
    return if @token

    raise CurlDownloadStrategyError,
      "arkho-cli is a private repo. Set HOMEBREW_GITHUB_API_TOKEN to a GitHub token with read " \
      "access (e.g. `export HOMEBREW_GITHUB_API_TOKEN=$(gh auth token)`) and retry."
  end

  private

  def _fetch(url:, resolved_url:, timeout:)
    require "json"
    api = "https://api.github.com/repos/#{@owner}/#{@repo}/releases/tags/#{@tag}"
    release = JSON.parse(Utils::Curl.curl_output(
      "--header", "Authorization: token #{@token}",
      "--header", "Accept: application/vnd.github+json", api
    ).stdout)
    asset = release["assets"].find { |a| a["name"] == @filename }
    raise CurlDownloadStrategyError, "Asset #{@filename} not found in #{@tag}" unless asset

    curl_download "https://api.github.com/repos/#{@owner}/#{@repo}/releases/assets/#{asset["id"]}",
      "--header", "Accept: application/octet-stream",
      "--header", "Authorization: token #{@token}",
      to: temporary_path
  end
end

class ArkhoCli < Formula
  desc "ARKHO's internal CLI for generating versioned project templates"
  homepage "https://github.com/tenondecrpc/arkho-cli"
  version "0.1.0"

  on_macos do
    on_arm do
      url "https://github.com/tenondecrpc/arkho-cli/releases/download/v0.1.0/arkho-cli-0.1.0-darwin-arm64",
        using: GitHubPrivateReleaseDownloadStrategy
      sha256 "f4b6653d576442dcc77bc14cd21bdcd12770b0d7b77a046086ee22bfbc2982ce"
    end
    on_intel do
      url "https://github.com/tenondecrpc/arkho-cli/releases/download/v0.1.0/arkho-cli-0.1.0-darwin-x64",
        using: GitHubPrivateReleaseDownloadStrategy
      sha256 "17d8f775158e5d7b1c441fa088a3042ff369bfabd6b306dc6eb48649d1eabc49"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/tenondecrpc/arkho-cli/releases/download/v0.1.0/arkho-cli-0.1.0-linux-arm64",
        using: GitHubPrivateReleaseDownloadStrategy
      sha256 "8438bd45fe349a98e940ff9b7985b13643b46a8a2483708aa430f7e2a6d9088c"
    end
    on_intel do
      url "https://github.com/tenondecrpc/arkho-cli/releases/download/v0.1.0/arkho-cli-0.1.0-linux-x64",
        using: GitHubPrivateReleaseDownloadStrategy
      sha256 "3aa4c88589f5d3da497bc43503535ae7241f6d6a01b72ea17199331178a32de6"
    end
  end

  def install
    bin.install Dir["arkho-cli-*"].first => "arkho-cli"
  end

  test do
    assert_match "fetch-template", shell_output("#{bin}/arkho-cli 2>&1", 1)
  end
end
