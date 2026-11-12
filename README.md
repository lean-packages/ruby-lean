# ruby-lean

Validate and inspect RubyGem package contents to keep your published gems lean.

## Why?

When you publish a Ruby gem to RubyGems.org, RubyGems packages all files resolved by `Gem::Specification#files` in your `.gemspec`. In many gems, files are selected using loose directory globs (`Dir["**/*"]`) or broad `git ls-files` commands. That means your published gem can unintentionally include development artefacts like IDE settings, test suites, build output, documentation drafts, and CI configuration. These files bloat the gem download size, slow down `gem install` and `bundle install`, and expose internal project structure to downstream users.

`ruby-lean` audits your `.gemspec` file list and verifies built `.gem` archives so only the source code and assets your users need end up in the published gem.

## Installation

### From RubyGems

```bash
gem install ruby-lean
```

### From source

```bash
git clone git@github.com:lean-packages/ruby-lean.git && cd ruby-lean
rake build
gem install ./ruby-lean-*.gem
```

This places the `ruby-lean` binary in your Ruby environment's executable directory, which should be on your PATH.

## Usage

```
ruby-lean <COMMAND>
```

### Commands

| Command | Description |
|---|---|
| `lint`  | Check if any unnecessary or invalid files are included in the gem. |

### `lint` — Check package contents

Verifies that all files declared in `.gemspec` and packaged in `.gem` meet leanness and validity policies.

```bash
# Check the current directory
ruby-lean lint

# Check a specific project directory
ruby-lean lint /path/to/my-gem

# Check a specific gemspec file
ruby-lean lint --gemspec /path/to/my-gem.gemspec

# Fail on advisory warnings (recommended for CI)
ruby-lean lint --strict

# Inspect gemspec file list only without building an archive
ruby-lean lint --no-archive

# JSON output for scripting
ruby-lean lint --format json
```

__`--strict` flag:__ Treats advisory warnings (such as development test files, CI metadata, and build tools) as failures, exiting with code `1`.

__`--no-archive` flag:__ Skips building a temporary `.gem` archive and inspects only the effective gemspec file list on disk.

## Options and flags

All commands support these options and flags:

| Option / Flag | Description |
|---|---|
| `--gemspec <PATH>` | Path to explicit `.gemspec` file |
| `-f, --format <FORMAT>` | Output format: `text` or `json` (default: `text`) |
| `-s, --strict` | Treat advisory warnings as errors |
| `--no-archive` | Skip building and verifying temporary `.gem` archive |
| `-q, --quiet` | Suppress non-essential informational output |
| `-v, --version` | Print version information |
| `-h, --help` | Show help message |

## Lint rules

`ruby-lean` evaluates package contents against high-signal rules:

### Errors (Always fail policy)

| Rule ID | Description |
|---|---|
| `RUBYLEAN_INVALID_SPEC` | Gemspec syntax error, unloadable specification, or validation failure. |
| `RUBYLEAN_MISSING_FILE` | Declared file does not exist on disk. |
| `RUBYLEAN_INVALID_PATH` | Absolute path, directory entry, or path escaping the gem root (`../`). |
| `RUBYLEAN_BUILD_ERROR` | RubyGems archive packaging failure. |
| `RUBYLEAN_ARCHIVE_MISMATCH` | Discrepancy between gemspec declared files and actual `.gem` archive contents. |

### Advisory warnings (Fail with `--strict`)

| Rule ID | Description |
|---|---|
| `RUBYLEAN_DEV_FILE` | Test or specification files (`spec/`, `test/`, `features/`) included in gem. |
| `RUBYLEAN_CI_METADATA` | CI configuration files (`.github/`, `.gitlab/`, `.circleci/`, etc.) included. |
| `RUBYLEAN_COVERAGE` | Test coverage artifacts or configs (`coverage/`, `.simplecov`) included. |
| `RUBYLEAN_EDITOR_CONFIG` | Editor or IDE configuration files (`.vscode/`, `.idea/`, etc.) included. |
| `RUBYLEAN_BUILD_TOOL` | Development build tools (`Gemfile`, `Gemfile.lock`, `Rakefile`, `.rubocop.yml`) included. |
| `RUBYLEAN_VCS_METADATA` | VCS metadata (`.gitignore`, `.gitattributes`) included. |
| `RUBYLEAN_GIT_DEPENDENT` | Gemspec source relies on `git ls-files` for dynamic file discovery (advisory). |
| `RUBYLEAN_SYMLINK` | Packaged file is a symbolic link. |

*Note:* Standard documentation and runtime assets (`README*`, `LICENSE*`, `CHANGELOG*`, `CONTRIBUTING*`, `docs/`, `lib/`, `exe/`) are explicitly preserved and never flagged.

## Exit codes

| Exit Code | Status | Description |
|---|---|---|
| `0` | `SUCCESS` | Gem passed policy (0 errors; warnings allowed unless `--strict`). |
| `1` | `LINT_FAILED` | Lint policy failed (errors found, or warnings found with `--strict`). |
| `2` | `EXECUTION_ERROR` | Usage error, invalid options, missing gemspec, or gemspec evaluation failure. |

## CI integration

Add `ruby-lean lint` to your CI pipeline to enforce that gem packages stay clean:

```yaml
# Example GitHub Actions step
- name: Check RubyGem package contents
  run: ruby-lean lint --strict
```

## JSON output

All commands support `--format json` for scripting and automation. Example `lint` output:

```json
{
  "schemaVersion": "1",
  "tool": {
    "name": "ruby-lean",
    "version": "0.1.0"
  },
  "package": {
    "name": "example-gem",
    "version": "1.0.0",
    "gemspec": "example-gem.gemspec"
  },
  "inspection": {
    "mode": "archive",
    "archiveVerified": true,
    "fileCount": 4,
    "totalBytes": 1420
  },
  "summary": {
    "errors": 0,
    "warnings": 1,
    "info": 0
  },
  "findings": [
    {
      "rule": "RUBYLEAN_DEV_FILE",
      "severity": "warning",
      "message": "Development-oriented test or specification files are included in the package.",
      "paths": [
        "spec/example_spec.rb"
      ],
      "suggestedAction": "Filter out test directories (spec/, test/, features/) from spec.files in your gemspec."
    }
  ]
}
```

## Security considerations

A `.gemspec` file contains executable Ruby code. Evaluating a gemspec via RubyGems executes Ruby instructions. `ruby-lean` is intended for **trusted local gem repositories** and maintainers inspecting their own code. Evaluating untrusted gemspecs is not sandboxed.

## AI disclaimer

This package is developed with the assistance of Artificial Intelligence (AI). AI tools are used throughout the development
process, including code generation, documentation, testing, and maintenance.

While reasonable care is taken to review and validate AI-generated contributions, AI-generated code is not inherently correct,
secure, or free of defects. All contributions remain subject to human review and project quality standards.

As with any software, use this package at your own risk. No guarantee is made regarding its fitness for a particular purpose,
and the maintainers assume no liability for damages resulting from its use.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for development instructions.

## License

This project is licensed under the MIT license. Please see [LICENSE.md](LICENSE.md) for more details.

## Related projects

- [cargo-lean](https://github.com/lean-packages/cargo-lean) — The `Rust` counterpart.
- [php-lean](https://github.com/lean-packages/php-lean) — The `PHP` counterpart.
- [py-lean](https://github.com/lean-packages/py-lean) — The `Python` equivalent.
- [js-lean](https://github.com/lean-packages/js-lean) — The `JavaScript` equivalent.
