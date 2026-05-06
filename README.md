# homebrew-tap

Personal Homebrew tap for [@tenondecrpc](https://github.com/tenondecrpc).

## Available formulas

| Formula | Source |
|---|---|
| `claude-statusline` | https://github.com/tenondecrpc/claude-statusline |

## Usage

```bash
brew tap tenondecrpc/tap
brew install <formula-name>
```

For example:

```bash
brew tap tenondecrpc/tap
brew install claude-statusline
```

## Updating a formula

When a new release is published in the source repo:

1. Bump `url` to the new tag tarball.
2. Update `sha256` with the output of:
   ```bash
   curl -fsSL "<new-tarball-url>" | shasum -a 256
   ```
3. Commit and push. Users get the new version with `brew upgrade <formula-name>`.
