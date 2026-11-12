# ruby-lean Architecture and Verification

## 1. Overview and Mission

`ruby-lean` is a Ruby-native auditing CLI tool designed to inspect, analyze, and lint RubyGem distribution packages. Its primary objective is to help gem maintainers identify unnecessary, suspicious, or broken files in gem distributions before publishing, ensuring clean, minimal, and secure gems.

### Key Principles
- **Native Packaging Control:** Uses RubyGems' native inclusion mechanism (`.gemspec` and `Gem::Specification#files`). It does not invent synthetic exclude manifests or custom packaging formats.
- **Read-Only Operation:** Audits and diagnoses packages without altering source files, rewriting gemspecs, or modifying repository state.
- **Dual-Layer Inspection:** Distinguishes between the *effective gemspec file list* and the *actual archive contents* of a built `.gem` package.
- **Advisory by Default:** Flags development, test, and CI artifacts as advisory warnings rather than strict errors, while allowing maintainers to enforce `--strict` policy in CI.
- **Zero Runtime Dependencies:** Relies solely on the Ruby standard library and core RubyGems APIs.

---

## 2. Verified RubyGems Behavior

### 2.1 How `Gem::Specification#files` Computes Effective Files
In RubyGems, `Gem::Specification#files` computes the union of declared package files by combining:
1. `spec.files` (primary files array)
2. `spec.executables` (prefixed with `spec.bindir`, defaulting to `bin/`)
3. `spec.extensions` (native extension build scripts such as `ext/**/extconf.rb`)
4. `spec.extra_rdoc_files` (documentation files)
5. `spec.test_files` (legacy test file declaration, if present)

RubyGems automatically deduplicates and sorts the resulting array:
```ruby
# Effective computation in RubyGems Specification:
files = @files + @test_files + @extra_rdoc_files + @extensions + @executables.map { |e| File.join(@bindir, e) }
files.uniq.compact.sort
```

### 2.2 Path Handling and Traversal
- **Missing Files:** If a file listed in `spec.files` does not exist on disk, `Gem::Specification.load` will still return the specification, but building the gem or running validation (`spec.validate`) will fail with `Gem::InvalidSpecificationException`.
- **Absolute and Parent Paths:** Paths starting with `/` or containing `../` traversal that escape the gem root are invalid and rejected by RubyGems build validation.
- **Symlinks:** Symlinks pointing outside the project tree or broken symlinks can cause packaging issues or inadvertent file exposure. `ruby-lean` explicitly checks for symlinks and path validity.
- **Deduplication:** Multiple entries pointing to the same file are collapsed by `Gem::Specification#files`.

### 2.3 Gemspec Discovery Patterns
Ruby gemspecs commonly populate `spec.files` using one of three patterns:
1. **Explicit array:** `spec.files = ["lib/foo.rb", "README.md", "LICENSE"]`
2. **`Dir.glob`:** `spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE"]`
3. **`git ls-files`:** `spec.files = `git ls-files -z`.split("\x0")`

**Crucial Caveat regarding `.gitignore` vs Packaging:**
`.gitignore` is a version control mechanism, not a RubyGems packaging control. Gemspecs that use `Dir["**/*"]` or loose globs often inadvertently include `Gemfile`, `Gemfile.lock`, CI configs, and test artifacts. Even `git ls-files` includes all committed repository files (tests, spec helpers, benchmarks) unless filtered.

### 2.4 Gemspec Security Context
A `.gemspec` is executable Ruby code. Evaluating a gemspec via `Gem::Specification.load` or `eval` executes arbitrary Ruby instructions. `ruby-lean` operates on **trusted local gems** and documents that gemspec loading must never be performed on untrusted code under the assumption of isolation.

---

## 3. Archive Verification Strategy

`ruby-lean` supports two analysis modes:
1. **Archive Mode (default):**
   - Invokes `gem build <gemspec> --output <temp_gem>` in an isolated temporary directory (`Dir.mktmpdir`).
   - Ensures no `.gem` file or build artifact is written into the project directory.
   - Inspects the built archive using `Gem::Package::TarReader` and `Gem::Package.new(path).contents`.
   - Reads exact packaged file names and uncompressed byte sizes from the `data.tar.gz` entry.
   - Compares actual archive entries against the expected effective gemspec file list.
   - Cleans up the temporary directory reliably in an `ensure` block.
2. **Specification-Only Mode (`--no-archive`):**
   - Evaluates the gemspec and verifies file presence on disk without running `gem build`.
   - Useful in restricted environments where building is skipped or native compilers are absent.

---

## 4. Lint Rules and Severities

| Rule ID | Severity | Description |
|---|---|---|
| `RUBYLEAN_INVALID_SPEC` | Error | Gemspec syntax error, unloadable specification, or validation failure. |
| `RUBYLEAN_MISSING_FILE` | Error | File declared in gemspec does not exist on disk. |
| `RUBYLEAN_INVALID_PATH` | Error | File path is absolute, contains `../` traversal, or escapes project root. |
| `RUBYLEAN_BUILD_ERROR` | Error | `gem build` failed or produced invalid archive. |
| `RUBYLEAN_ARCHIVE_MISMATCH` | Error | Discrepancy between gemspec effective list and archive contents. |
| `RUBYLEAN_DEV_FILE` | Warning | Test or specification files (`spec/`, `test/`, `features/`) included in gem. |
| `RUBYLEAN_CI_METADATA` | Warning | CI configuration files (`.github/`, `.gitlab/`, `.circleci/`, etc.) included. |
| `RUBYLEAN_COVERAGE` | Warning | Test coverage artifacts or configs (`coverage/`, `.simplecov`) included. |
| `RUBYLEAN_EDITOR_CONFIG` | Warning | Editor / IDE configuration files (`.vscode/`, `.idea/`, etc.) included. |
| `RUBYLEAN_BUILD_TOOL` | Warning | Development build tools (`Gemfile`, `Gemfile.lock`, `Rakefile`, `.rubocop.yml`) included. |
| `RUBYLEAN_VCS_METADATA` | Warning | VCS metadata (`.git/`, `.gitignore`, `.gitattributes`) included. |
| `RUBYLEAN_GIT_DEPENDENT` | Warning | Gemspec source relies on `git ls-files` for dynamic file discovery (advisory). |
| `RUBYLEAN_SYMLINK` | Warning | Packaged file is a symbolic link. |

---

## 5. Exit Code Contract

- `0` (`SUCCESS`): No errors, and no warnings (or warnings present without `--strict`).
- `1` (`LINT_FAILED`): Lint policy failure (errors present, or warnings present with `--strict`).
- `2` (`EXECUTION_ERROR`): Usage error, invalid CLI flags, gemspec not found, or fatal execution failure.

---

## 6. Compatibility Matrix

- **Ruby:** 2.6, 2.7, 3.0, 3.1, 3.2, 3.3, 3.4+
- **RubyGems:** 3.0+
- **Platform:** OS-independent (macOS, Linux, Windows)
