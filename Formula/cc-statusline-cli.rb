class CcStatuslineCli < Formula
  desc "Configurable statusline command for Claude Code"
  homepage "https://github.com/tenondecrpc/cc-statusline"
  url "https://github.com/tenondecrpc/cc-statusline/archive/refs/tags/v0.2.13.tar.gz"
  sha256 "dfaeadbe6a69358a0e1fe00e9980287aa7ad92fdc425dc35e952112aedf63037"
  license "MIT"

  depends_on "jq"

  def install
    libexec.install "statusline.sh", "install.sh", "uninstall.sh", "package.json"
    (libexec/"lib").install Dir["lib/*"]
    (libexec/"presets").install Dir["presets/*"]

    # Use opt_libexec (stable symlink) so settings.json and the wrapper survive
    # `brew upgrade`, which otherwise leaves them pointing at a version-pinned
    # Cellar path that disappears on the next install.
    (bin/"cc-statusline").write <<~SCRIPT
      #!/usr/bin/env bash
      set -uo pipefail

      LIBEXEC="#{opt_libexec}"

      cmd="${1:-help}"
      shift 2>/dev/null || true

      forward_to_npm() {
        local npm_global
        npm_global="$(npm config get prefix 2>/dev/null || true)"
        if [ -z "$npm_global" ] && command -v node >/dev/null 2>&1; then
          npm_global="$(node -e "const p=require('path');const n=process;console.log(n.env.npm_config_prefix || p.resolve(n.execPath,'../../lib/node_modules'))" 2>/dev/null || true)"
        fi
        if [ -n "$npm_global" ]; then
          local js_bin="${npm_global}/lib/node_modules/cc-statusline-cli/bin/cc-statusline.js"
          if [ -f "$js_bin" ]; then
            exec node "$js_bin" "$cmd" "$@"
          fi
        fi
      }

      case "$cmd" in
        version)
          if [ -f "$LIBEXEC/package.json" ] && command -v jq >/dev/null 2>&1; then
            jq -r '"v" + .version' "$LIBEXEC/package.json"
          else
            printf 'unknown\n'
          fi
          ;;
        install|configure)
          forward_to_npm
          CCSL_INSTALL_DIR="$LIBEXEC" CCSL_SKIP_WRAPPER=1 bash "$LIBEXEC/install.sh" "$@"
          ;;
        render)
          forward_to_npm
          exec bash "$LIBEXEC/statusline.sh" </dev/stdin
          ;;
        update)
          printf 'Use Homebrew to update:\n  brew update && brew upgrade cc-statusline-cli\n' >&2
          exit 1
          ;;
        uninstall)
          forward_to_npm
          if [ -f "$LIBEXEC/uninstall.sh" ]; then
            bash "$LIBEXEC/uninstall.sh" "$@"
          else
            printf 'Use Homebrew to uninstall:\n  brew uninstall cc-statusline-cli\n' >&2
            printf 'Restore the previous statusLine from ~/.claude/settings.json.bak.* or remove the entry manually before uninstalling.\n' >&2
          fi
          ;;
        help|--help|-h|"")
          cat <<'HELP'
      Usage: cc-statusline <command> [args]

      Commands:
        install     configure Claude Code to use cc-statusline
        configure   alias for install
        render      read Claude Code session JSON from stdin and render the statusline
        version     show the installed version
        update      points you at 'brew upgrade cc-statusline-cli'
        uninstall   restore settings.json backup and uninstall
        help        show this help

      Examples:
        cc-statusline install --force
        cc-statusline install --keep-existing
        cc-statusline uninstall
        cc-statusline uninstall --purge
      HELP
          ;;
        *)
          forward_to_npm
          printf 'Unknown command: %s\n' "$cmd" >&2
          printf "Run 'cc-statusline help' for usage.\n" >&2
          exit 1
          ;;
      esac
    SCRIPT
    chmod 0755, bin/"cc-statusline"
  end

  def caveats
    <<~EOS
      To wire cc-statusline into Claude Code, run:
        cc-statusline configure

      That points ~/.claude/settings.json at:
        #{opt_libexec}/statusline.sh

      Use `--keep-existing` to preserve a custom statusLine, or `--force`
      to replace one.

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
