class CcStatuslineCli < Formula
  desc "Configurable statusline command for Claude Code"
  homepage "https://github.com/tenondecrpc/cc-statusline"
  url "https://github.com/tenondecrpc/cc-statusline/archive/refs/tags/v0.2.2.tar.gz"
  sha256 "716d8082edc91ab0966314319281fa963d31a65a8898c7b3edae15f87910584f"
  license "MIT"

  depends_on "jq"

  def install
    libexec.install "statusline.sh", "install.sh", "uninstall.sh", "package.json", "lib", "presets"

    # Use opt_libexec (stable symlink) so settings.json and the wrapper survive
    # `brew upgrade`, which otherwise leaves them pointing at a version-pinned
    # Cellar path that disappears on the next install.
    (bin/"cc-statusline").write <<~SCRIPT
      #!/usr/bin/env bash
      set -uo pipefail

      LIBEXEC="#{opt_libexec}"

      cmd="${1:-help}"
      shift 2>/dev/null || true

      case "$cmd" in
        version)
          if [ -f "$LIBEXEC/package.json" ] && command -v jq >/dev/null 2>&1; then
            jq -r '"v" + .version' "$LIBEXEC/package.json"
          else
            printf 'unknown\\n'
          fi
          ;;
        configure)
          CCSL_INSTALL_DIR="$LIBEXEC" CCSL_SKIP_WRAPPER=1 bash "$LIBEXEC/install.sh" "$@"
          ;;
        update)
          printf 'Use Homebrew to update:\\n  brew update && brew upgrade cc-statusline-cli\\n' >&2
          exit 1
          ;;
        uninstall)
          printf 'Use Homebrew to uninstall:\\n  brew uninstall cc-statusline-cli\\n' >&2
          printf 'Restore the previous statusLine from ~/.claude/settings.json.bak.* or remove the entry manually before uninstalling.\\n' >&2
          exit 1
          ;;
        help|--help|-h|"")
          cat <<'HELP'
      Usage: cc-statusline <command> [args]

      Commands:
        configure   wire up ~/.claude/settings.json (forwards args to install.sh)
        version     show the installed version
        update      points you at 'brew upgrade cc-statusline-cli'
        uninstall   points you at 'brew uninstall cc-statusline-cli'
        help        show this help

      Examples:
        cc-statusline configure --force
        cc-statusline configure --keep-existing
      HELP
          ;;
        *)
          printf 'Unknown command: %s\\n' "$cmd" >&2
          printf "Run 'cc-statusline help' for usage.\\n" >&2
          exit 1
          ;;
      esac
    SCRIPT
    chmod 0755, bin/"cc-statusline"
  end

  def post_install
    # Wire up ~/.claude/settings.json automatically. Use --keep-existing so a user's
    # custom statusLine is preserved; they can replace it with `cc-statusline
    # configure --force`. CCSL_SKIP_WRAPPER=1 prevents install.sh from creating its own
    # ~/.local/bin/cc-statusline shim, since brew already owns bin/cc-statusline.
    with_env CCSL_INSTALL_DIR: opt_libexec.to_s, CCSL_SKIP_WRAPPER: "1" do
      system "bash", libexec/"install.sh", "--keep-existing", "--non-interactive"
    end
  end

  def caveats
    <<~EOS
      cc-statusline has been wired up automatically. ~/.claude/settings.json
      now points at:
        #{opt_libexec}/statusline.sh

      If you already had a custom statusLine, it was kept. Replace it with:
        cc-statusline configure --force

      Edit your preset:
        ~/.config/cc-statusline/config.json

      Before `brew uninstall cc-statusline-cli`, restore your previous
      statusLine from ~/.claude/settings.json.bak.* or delete the statusLine
      entry manually, otherwise Claude Code will reference a missing script.
    EOS
  end

  test do
    payload = {
      model:          { display_name: "Sonnet" },
      workspace:      { current_dir: "." },
      context_window: { used_percentage: 42 },
      cost:           {
        total_cost_usd:      0.12,
        total_duration_ms:   60_000,
        total_lines_added:   0,
        total_lines_removed: 0,
      },
    }.to_json
    output = pipe_output("#{libexec}/statusline.sh", payload, 0)
    assert_match "Sonnet", output
  end
end
