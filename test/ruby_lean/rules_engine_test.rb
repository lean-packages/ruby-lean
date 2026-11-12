# frozen_string_literal: true

require_relative "../test_helper"

class RulesEngineTest < Minitest::Test
  def test_clean_gem_has_no_findings
    dir = create_fixture_gem("cleangem", files: {
      "lib/cleangem.rb" => "module CleanGem; end",
      "README.md" => "# Clean Gem",
      "LICENSE" => "MIT",
      "CHANGELOG.md" => "# Changelog"
    })

    package = RubyLean::GemspecLoader.discover_and_load(dir)
    findings = RubyLean::Rules::Engine.audit(package)

    assert_empty findings
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_missing_files_finding
    dir = create_fixture_gem("missinggem", files: {
      "lib/existing.rb" => "1"
    }, gemspec_body: <<-RUBY)
      Gem::Specification.new do |s|
        s.name = "missinggem"
        s.version = "1.0.0"
        s.summary = "summary"
        s.authors = ["Jane"]
        s.files = ["lib/existing.rb", "lib/nonexistent.rb"]
      end
    RUBY

    package = RubyLean::GemspecLoader.discover_and_load(dir)
    findings = RubyLean::Rules::Engine.audit(package)

    missing = findings.find { |f| f.rule == "RUBYLEAN_MISSING_FILE" }
    refute_nil missing
    assert missing.error?
    assert_includes missing.paths, "lib/nonexistent.rb"
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_invalid_path_finding_for_parent_traversal_and_absolute_paths
    dir = create_fixture_gem("invalidpath", files: {
      "lib/foo.rb" => "1"
    }, gemspec_body: <<-RUBY)
      Gem::Specification.new do |s|
        s.name = "invalidpath"
        s.version = "1.0.0"
        s.summary = "summary"
        s.authors = ["Jane"]
        s.files = ["lib/foo.rb", "../outside.rb", "/etc/passwd"]
      end
    RUBY

    package = RubyLean::GemspecLoader.discover_and_load(dir)
    findings = RubyLean::Rules::Engine.audit(package)

    invalid = findings.find { |f| f.rule == "RUBYLEAN_INVALID_PATH" }
    refute_nil invalid
    assert invalid.error?
    assert_includes invalid.paths, "../outside.rb"
    assert_includes invalid.paths, "/etc/passwd"
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_development_files_findings
    dir = create_fixture_gem("devgem", files: {
      "lib/devgem.rb" => "1",
      "spec/devgem_spec.rb" => "1",
      "test/test_devgem.rb" => "1",
      "features/step_definitions/steps.rb" => "1"
    })

    package = RubyLean::GemspecLoader.discover_and_load(dir)
    findings = RubyLean::Rules::Engine.audit(package)

    dev_finding = findings.find { |f| f.rule == "RUBYLEAN_DEV_FILE" }
    refute_nil dev_finding
    assert dev_finding.warning?
    assert_includes dev_finding.paths, "spec/devgem_spec.rb"
    assert_includes dev_finding.paths, "test/test_devgem.rb"
    assert_includes dev_finding.paths, "features/step_definitions/steps.rb"
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_ci_metadata_finding
    dir = create_fixture_gem("cigem", files: {
      "lib/cigem.rb" => "1",
      ".github/workflows/ci.yml" => "1",
      ".travis.yml" => "1"
    })

    package = RubyLean::GemspecLoader.discover_and_load(dir)
    findings = RubyLean::Rules::Engine.audit(package)

    ci_finding = findings.find { |f| f.rule == "RUBYLEAN_CI_METADATA" }
    refute_nil ci_finding
    assert ci_finding.warning?
    assert_includes ci_finding.paths, ".github/workflows/ci.yml"
    assert_includes ci_finding.paths, ".travis.yml"
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_coverage_and_editor_and_build_tools_and_vcs
    dir = create_fixture_gem("kitchensink", files: {
      "lib/app.rb" => "1",
      "coverage/index.html" => "1",
      ".simplecov" => "1",
      ".vscode/settings.json" => "1",
      ".editorconfig" => "1",
      "Gemfile" => "1",
      "Gemfile.lock" => "1",
      "Rakefile" => "1",
      ".rubocop.yml" => "1",
      ".gitignore" => "1"
    })

    package = RubyLean::GemspecLoader.discover_and_load(dir)
    findings = RubyLean::Rules::Engine.audit(package)

    rules = findings.map(&:rule)
    assert_includes rules, "RUBYLEAN_COVERAGE"
    assert_includes rules, "RUBYLEAN_EDITOR_CONFIG"
    assert_includes rules, "RUBYLEAN_BUILD_TOOL"
    assert_includes rules, "RUBYLEAN_VCS_METADATA"
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_symlink_finding
    dir = create_fixture_gem("symgem", files: {
      "lib/symgem.rb" => "1",
      "lib/target.rb" => "1"
    })

    symlink_path = File.join(dir, "lib/link.rb")
    File.symlink("target.rb", symlink_path)

    gemspec_path = File.join(dir, "symgem.gemspec")
    File.write(gemspec_path, <<-RUBY)
      Gem::Specification.new do |s|
        s.name = "symgem"
        s.version = "1.0.0"
        s.summary = "summary"
        s.authors = ["Jane"]
        s.files = ["lib/symgem.rb", "lib/link.rb"]
      end
    RUBY

    package = RubyLean::GemspecLoader.discover_and_load(dir)
    findings = RubyLean::Rules::Engine.audit(package)

    symlink_finding = findings.find { |f| f.rule == "RUBYLEAN_SYMLINK" }
    refute_nil symlink_finding
    assert_includes symlink_finding.paths, "lib/link.rb"
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_archive_mismatch_finding
    dir = create_fixture_gem("mismatchgem", files: {
      "lib/mismatchgem.rb" => "1"
    })

    package = RubyLean::GemspecLoader.discover_and_load(dir)
    # Simulate archive missing a declared file or having an extra file
    findings = RubyLean::Rules::Engine.audit(package, archive_files: ["lib/extra.rb"])

    mismatch = findings.find { |f| f.rule == "RUBYLEAN_ARCHIVE_MISMATCH" }
    refute_nil mismatch
    assert mismatch.error?
  ensure
    FileUtils.rm_rf(dir) if dir
  end
end
