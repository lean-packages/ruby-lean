# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-11-13

### Added

- __`lint` command__: Checks whether all files declared in `.gemspec` and included in `.gem` packages comply with leanness and packaging rules.
- __Dual-layer inspection__: Analyzes effective gemspec declarations (`Gem::Specification#files`) and verifies built `.gem` archive contents in isolated temporary storage.
- __Lint rules__: Comprehensive detection of missing files, invalid paths, test suites, CI metadata, coverage reports, editor settings, development build tools, VCS files, and dynamic `git ls-files` discovery.
- __`--strict` flag__: Enables failing exit code on advisory warnings for CI pipelines.
- __`--no-archive` flag__: Allows specification-only inspection without building `.gem` archives.
- __`--format json` option__: Structured, deterministic JSON output for scripting and CI integration.
- __`--gemspec` option__: Explicitly specify `.gemspec` file path.
