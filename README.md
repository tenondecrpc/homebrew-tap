# homebrew-tap

Personal Homebrew tap for [@tenondecrpc](https://github.com/tenondecrpc).

## Available formulas

| Formula | Source |
|---|---|
| `cc-statusline-cli` | https://github.com/tenondecrpc/cc-statusline |
| `arkho-cli` | https://github.com/tenondecrpc/arkho-cli (private - needs a token, see below) |

## Usage

```bash
brew tap tenondecrpc/tap
brew install <formula-name>
```

For example:

```bash
brew tap tenondecrpc/tap
brew install cc-statusline-cli
```

### arkho-cli (private repo)

`arkho-cli` lives in a private repo, so Homebrew needs a GitHub token with read access to
download the release binary. Export one before installing (the formula reads
`HOMEBREW_GITHUB_API_TOKEN`):

```bash
export HOMEBREW_GITHUB_API_TOKEN="$(gh auth token)"   # or a PAT with repo read access
brew tap tenondecrpc/tap
brew install arkho-cli
```

Homebrew may ask you to trust the tap (the formula uses a custom download strategy):

```bash
brew trust --formula tenondecrpc/tap/arkho-cli
```

If `arkho-cli` is later made public, the token and trust steps are no longer needed.

## Updating a formula

### New source release

When a new release is published in the source repo:

1. Update `url` to the new tag tarball.
2. Update `sha256`:
   ```bash
   curl -fsSL "<new-tarball-url>" | shasum -a 256
   ```
3. Remove any `revision N` line (a new source version resets it).
4. Validate, commit, push:
   ```bash
   brew style Formula/<formula-name>.rb
   git add Formula/<formula-name>.rb
   git commit -m "chore: bump <formula-name> to vX.Y.Z"
   git push origin main
   ```

Users pick up the new version with `brew upgrade <formula-name>`.

### Formula-only fix

When only the formula needs to change (no source release), bump `revision N` after `license` instead of releasing a new tag:

```ruby
url "https://github.com/.../archive/refs/tags/vX.Y.Z.tar.gz"
sha256 "..."
license "MIT"
revision 1
```

Increment the number for each subsequent formula-only fix on the same source version. Existing installs pick up the change with `brew upgrade <formula-name>`.

### Authoritative release flow

The full release flow for `cc-statusline-cli`, including the `package.json` version bump and `gh release create` steps in the source repo, is documented in [tenondecrpc/cc-statusline `AGENTS.md` → Cutting a Release](https://github.com/tenondecrpc/cc-statusline/blob/main/AGENTS.md#cutting-a-release).
