# frozen_string_literal: true

require "pathname"
require "set"

module RubyLean
  module Rules
    class Engine
      def self.audit(package, archive_files: nil)
        new(package, archive_files: archive_files).audit
      end

      def initialize(package, archive_files: nil)
        @package = package
        @archive_files = archive_files
        @gem_root = package.gem_root
        @effective_files = package.effective_files
      end

      def audit
        findings = []

        # 1. Path validity and existence checks (Errors)
        findings.concat(check_paths_and_missing_files)

        # 2. Advisory warning checks
        findings.concat(check_dev_files)
        findings.concat(check_ci_metadata)
        findings.concat(check_coverage_artifacts)
        findings.concat(check_editor_configs)
        findings.concat(check_build_tools)
        findings.concat(check_vcs_metadata)
        findings.concat(check_symlinks)
        findings.concat(check_git_dependency)

        # 3. Archive mismatch checks (if archive was inspected)
        findings.concat(check_archive_mismatches) if @archive_files

        findings
      end

      private

      def check_paths_and_missing_files
        findings = []
        invalid_paths = []
        missing_files = []

        gem_root_pathname = Pathname.new(@gem_root).cleanpath

        @effective_files.each do |rel_path|
          # Check for absolute path or root escaping traversal
          if rel_path.start_with?("/") || rel_path.start_with?("\\")
            invalid_paths << rel_path
            next
          end

          expanded_path = File.expand_path(rel_path, @gem_root)
          expanded_pathname = Pathname.new(expanded_path).cleanpath

          # Check if path escapes gem root
          begin
            relative_to_root = expanded_pathname.relative_path_from(gem_root_pathname).to_s
            if relative_to_root.start_with?("..")
              invalid_paths << rel_path
              next
            end
          rescue ArgumentError
            invalid_paths << rel_path
            next
          end

          # Check existence
          if !File.exist?(expanded_path)
            missing_files << rel_path
          elsif File.directory?(expanded_path)
            # Declaring a directory as a file entry
            invalid_paths << rel_path
          end
        end

        if invalid_paths.any?
          findings << Model::Finding.new(
            rule: "RUBYLEAN_INVALID_PATH",
            severity: "error",
            message: "Gemspec contains absolute paths, directory entries, or paths traversing outside the gem root.",
            paths: invalid_paths,
            suggested_action: "Remove absolute paths and directory entries; ensure all paths are relative to the gem root."
          )
        end

        if missing_files.any?
          findings << Model::Finding.new(
            rule: "RUBYLEAN_MISSING_FILE",
            severity: "error",
            message: "Files referenced in gemspec effective file list do not exist on disk.",
            paths: missing_files,
            suggested_action: "Ensure declared files exist or remove non-existent references from spec.files."
          )
        end

        findings
      end

      def check_dev_files
        matches = @effective_files.select do |path|
          dev_file?(path)
        end

        return [] if matches.empty?

        [
          Model::Finding.new(
            rule: "RUBYLEAN_DEV_FILE",
            severity: "warning",
            message: "Development-oriented test or specification files are included in the package.",
            paths: matches,
            suggested_action: "Filter out test directories (spec/, test/, features/) from spec.files in your gemspec."
          )
        ]
      end

      def dev_file?(path)
        p = path.downcase
        # Test directories
        return true if p.start_with?("spec/", "test/", "tests/", "features/", "benchmarks/")
        return true if p.match?(%r{^[^/]+/(?:spec|test|tests|features)/})

        # Standalone test files outside lib/
        return true if !p.start_with?("lib/", "exe/", "bin/", "ext/") && (
          p.end_with?("_test.rb", "_spec.rb") ||
          File.basename(p).start_with?("test_")
        )

        false
      end

      def check_ci_metadata
        matches = @effective_files.select do |path|
          p = path.downcase
          p.start_with?(".github/", ".gitlab/", ".circleci/", ".buildkite/") ||
            %w[.travis.yml azure-pipelines.yml appveyor.yml .appveyor.yml .codecov.yml jenkinsfile].include?(File.basename(p))
        end

        return [] if matches.empty?

        [
          Model::Finding.new(
            rule: "RUBYLEAN_CI_METADATA",
            severity: "warning",
            message: "Continuous Integration (CI) configuration or workflow files are included in the package.",
            paths: matches,
            suggested_action: "Exclude .github/, .gitlab/, and other CI configurations from spec.files."
          )
        ]
      end

      def check_coverage_artifacts
        matches = @effective_files.select do |path|
          p = path.downcase
          p.start_with?("coverage/") || %w[.simplecov .simplecov_spawn].include?(File.basename(p))
        end

        return [] if matches.empty?

        [
          Model::Finding.new(
            rule: "RUBYLEAN_COVERAGE",
            severity: "warning",
            message: "Test coverage configuration or generated report artifacts are included in the package.",
            paths: matches,
            suggested_action: "Remove coverage reports and .simplecov from spec.files."
          )
        ]
      end

      def check_editor_configs
        matches = @effective_files.select do |path|
          p = path.downcase
          p.start_with?(".idea/", ".vscode/") ||
            %w[.editorconfig .project .classpath .settings].include?(File.basename(p)) ||
            p.end_with?(".swp", ".swo", "~")
        end

        return [] if matches.empty?

        [
          Model::Finding.new(
            rule: "RUBYLEAN_EDITOR_CONFIG",
            severity: "warning",
            message: "Editor or IDE configuration files are included in the package.",
            paths: matches,
            suggested_action: "Exclude editor and IDE configuration directories and files from spec.files."
          )
        ]
      end

      def check_build_tools
        build_tools_filenames = %w[
          gemfile gemfile.lock rakefile .rubocop.yml .rubocop_todo.yml
          .standard.yml .yardopts brewfile procfile .tool-versions .ruby-version
        ]

        matches = @effective_files.select do |path|
          base = File.basename(path).downcase
          build_tools_filenames.include?(base) || path.start_with?("bin/setup", "bin/console")
        end

        return [] if matches.empty?

        [
          Model::Finding.new(
            rule: "RUBYLEAN_BUILD_TOOL",
            severity: "warning",
            message: "Development build tools, linters, or lockfiles are included in the package.",
            paths: matches,
            suggested_action: "Exclude Gemfile, Rakefile, linters, and development scripts from spec.files."
          )
        ]
      end

      def check_vcs_metadata
        matches = @effective_files.select do |path|
          p = path.downcase
          p.start_with?(".git/", ".hg/", ".svn/") ||
            %w[.gitignore .gitattributes .gitmodules].include?(File.basename(p))
        end

        return [] if matches.empty?

        [
          Model::Finding.new(
            rule: "RUBYLEAN_VCS_METADATA",
            severity: "warning",
            message: "Version control system (VCS) metadata or configuration files are included in the package.",
            paths: matches,
            suggested_action: "Exclude .gitignore, .gitattributes, and other repository metadata from spec.files."
          )
        ]
      end

      def check_symlinks
        matches = @effective_files.select do |path|
          full_path = File.join(@gem_root, path)
          File.symlink?(full_path)
        end

        return [] if matches.empty?

        [
          Model::Finding.new(
            rule: "RUBYLEAN_SYMLINK",
            severity: "warning",
            message: "Symbolic link included in package files.",
            paths: matches,
            suggested_action: "Replace symlinks with regular files or ensure target files are valid package contents."
          )
        ]
      end

      def check_git_dependency
        return [] unless @package.git_dependent

        [
          Model::Finding.new(
            rule: "RUBYLEAN_GIT_DEPENDENT",
            severity: "warning",
            message: "Gemspec uses dynamic git ls-files discovery, which may include unneeded files or fail in non-git environments.",
            paths: [@package.relative_gemspec_path],
            suggested_action: "Use explicit file lists or filtered Dir.glob expressions instead of invoking git ls-files."
          )
        ]
      end

      def check_archive_mismatches
        gemspec_set = @effective_files.to_set
        archive_set = @archive_files.to_set

        missing_in_archive = (gemspec_set - archive_set).to_a.sort
        extra_in_archive = (archive_set - gemspec_set).to_a.sort

        findings = []
        if missing_in_archive.any? || extra_in_archive.any?
          discrepancy_details = []
          discrepancy_details.concat(missing_in_archive.map { |f| "#{f} (missing in .gem archive)" })
          discrepancy_details.concat(extra_in_archive.map { |f| "#{f} (present in archive but not in gemspec)" })

          findings << Model::Finding.new(
            rule: "RUBYLEAN_ARCHIVE_MISMATCH",
            severity: "error",
            message: "Discrepancy detected between gemspec declared files and actual built .gem archive contents.",
            paths: missing_in_archive + extra_in_archive,
            suggested_action: "Review gemspec file patterns and build process to ensure archive contents match expectations."
          )
        end

        findings
      end
    end
  end
end
