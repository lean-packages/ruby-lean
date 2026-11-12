# frozen_string_literal: true

require_relative "../test_helper"

class ReportersTest < Minitest::Test
  def setup
    @package = RubyLean::Model::Package.new(
      name: "demo",
      version: "1.2.3",
      gemspec_path: "/path/to/demo.gemspec",
      gem_root: "/path/to",
      effective_files: ["lib/demo.rb", "spec/demo_spec.rb"]
    )

    @findings = [
      RubyLean::Model::Finding.new(
        rule: "RUBYLEAN_DEV_FILE",
        severity: "warning",
        message: "Development test file included.",
        paths: ["spec/demo_spec.rb"],
        suggested_action: "Exclude spec/ directory."
      )
    ]

    @result = RubyLean::Model::Result.new(
      package: @package,
      inspection_mode: "archive",
      archive_verified: true,
      file_count: 2,
      total_bytes: 512,
      findings: @findings
    )
  end

  def test_text_reporter_renders_summary_and_findings
    text = RubyLean::Reporters::TextReporter.render(@result, strict: false)

    assert_includes text, "ruby-lean lint: demo 1.2.3"
    assert_includes text, "Archive verified (.gem)"
    assert_includes text, "Files:       2"
    assert_includes text, "512 B"
    assert_includes text, "WARNINGS (1):"
    assert_includes text, "[RUBYLEAN_DEV_FILE]"
    assert_includes text, "spec/demo_spec.rb"
    assert_includes text, "Summary: 0 error(s), 1 warning(s)"
    assert_includes text, "Policy passed."
  end

  def test_text_reporter_strict_mode_failure
    text = RubyLean::Reporters::TextReporter.render(@result, strict: true)

    assert_includes text, "(strict mode enabled)"
    assert_includes text, "Policy failed."
  end

  def test_json_reporter_schema
    json_str = RubyLean::Reporters::JsonReporter.render(@result)
    parsed = JSON.parse(json_str)

    assert_equal "1", parsed["schemaVersion"]
    assert_equal "ruby-lean", parsed["tool"]["name"]
    assert_equal RubyLean::VERSION, parsed["tool"]["version"]
    assert_equal "demo", parsed["package"]["name"]
    assert_equal "1.2.3", parsed["package"]["version"]
    assert_equal "archive", parsed["inspection"]["mode"]
    assert_equal true, parsed["inspection"]["archiveVerified"]
    assert_equal 2, parsed["inspection"]["fileCount"]
    assert_equal 512, parsed["inspection"]["totalBytes"]
    assert_equal 0, parsed["summary"]["errors"]
    assert_equal 1, parsed["summary"]["warnings"]
    assert_equal 1, parsed["findings"].size
    assert_equal "RUBYLEAN_DEV_FILE", parsed["findings"].first["rule"]
    assert_equal "warning", parsed["findings"].first["severity"]
    assert_equal ["spec/demo_spec.rb"], parsed["findings"].first["paths"]
    assert_equal "Exclude spec/ directory.", parsed["findings"].first["suggestedAction"]
  end
end
