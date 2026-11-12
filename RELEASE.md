# Release process

This document describes how to release a new version of `ruby-lean` to [RubyGems.org](https://rubygems.org).

Releases are published automatically via GitHub Actions whenever a version tag (e.g. `v0.2.0`) is pushed to the repository.

## Prerequisites

- Ensure you have write/admin permissions on the repository to push tags and commits to `main`.
- Ensure the `RUBYGEMS_API_KEY` secret is configured in GitHub repository secrets (Settings > Secrets and variables > Actions).
- Be on the `main` branch with a clean working tree and updated remote (`git pull origin main`).

## Release steps

1. Update `CHANGELOG.md` with the new version and release notes under a new version heading, moving items out of `[Unreleased]`.

2. Bump the version in `lib/ruby_lean/version.rb`.

3. Run the pre-release checks locally to verify tests and packaging rules pass:
   ```bash
   rake
   ```

4. Commit the release changes:
   ```bash
   git commit -am "chore: release v<version>"
   git push origin main
   ```

5. Tag and push the release tag:
   ```bash
   git tag -a v<version> -m "Release v<version>"
   git push origin v<version>
   ```

6. The release workflow (`.github/workflows/release.yml`) will trigger on the tag push, run tests, lint against packaging rules, build the `.gem` package, and publish it to [RubyGems.org](https://rubygems.org) using the API key.
