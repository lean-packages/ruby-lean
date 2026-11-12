# Contributing

Thank you for your interest in contributing to `ruby-lean`.

## Prerequisites

- Ruby 2.6+ (compatible with Ruby 2.7, 3.0, 3.1, 3.2, 3.3, 3.4+)
- [Rake](https://github.com/ruby/rake) — task runner for local development commands.

## Getting Started

After cloning the repository, follow these steps to set up the project:

```bash
git clone git@github.com:lean-packages/ruby-lean.git && cd ruby-lean
```

Verify the setup and run all checks to confirm everything works:

```bash
rake
```

## Code Quality

This project uses [Rake](https://github.com/ruby/rake) to manage common development commands.

See all available tasks with:

```bash
rake -T
```

### Check (recommended)

Run the test suite and leanness validation in one command:

```bash
rake
```

### Testing

Run the full test suite:

```bash
rake test
```

### Validating leanness

Validate package leanness against the current repository state:

```bash
rake lint
```

### Package build

Build the `.gem` package artifact:

```bash
rake build
```

## Pull Requests

Please open pull requests against the `main` branch from a dedicated feature branch. Use descriptive branch names that reflect the change, such as:

- `feat/lint-rule`
- `fix/archive-inspector`
- `docs/update-readme`

Before opening a PR, ensure:

1. `rake` passes locally (tests and lint).
2. `CHANGELOG.md` is updated under the `[Unreleased]` section with a summary of changes.
3. All commit messages follow [Conventional Commits](https://www.conventionalcommits.org/).

## Commit Messages

Please follow [Conventional Commits](https://www.conventionalcommits.org/) for all commit messages. This keeps the history readable and enables automated changelog generation. You can inspect the message schema for this project via `git log --oneline -n 10`.

Common types used in this project:

- `feat:` — new features or behavior changes
- `fix:` — bug fixes
- `docs:` — documentation updates
- `refactor:` — code changes that neither fix bugs nor add features
- `test:` — adding or updating tests
- `chore:` — maintenance tasks (dependencies, config, etc.)
