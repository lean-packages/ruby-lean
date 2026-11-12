# frozen_string_literal: true

require_relative "../test_helper"

class CLITest < Minitest::Test
  def capture_io
    orig_stdout = $stdout
    orig_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    [$stdout.string, $stderr.string]
  ensure
    $stdout = orig_stdout
    $stderr = orig_stderr
  end

  def test_version_flag
    stdout, stderr = capture_io do
      status = RubyLean::CLI.start(["--version"])
      assert_equal 0, status
    end
    assert_includes stdout, "ruby-lean #{RubyLean::VERSION}"
    assert_empty stderr
  end

  def test_help_flag
    stdout, stderr = capture_io do
      status = RubyLean::CLI.start(["--help"])
      assert_equal 0, status
    end
    assert_includes stdout, "Usage: ruby-lean lint"
    assert_empty stderr
  end

  def test_invalid_option_returns_code_2
    stdout, stderr = capture_io do
      status = RubyLean::CLI.start(["--invalid-flag"])
      assert_equal 2, status
    end
    assert_includes stderr, "Error:"
  end

  def test_lint_clean_gem_returns_0
    dir = create_fixture_gem("cliclean", files: {
      "lib/cliclean.rb" => "module CliClean; end",
      "README.md" => "# Clean"
    })

    stdout, stderr = capture_io do
      status = RubyLean::CLI.start(["lint", dir])
      assert_equal 0, status
    end
    assert_includes stdout, "Policy passed."
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_lint_warn_gem_returns_0_normally_and_1_with_strict
    dir = create_fixture_gem("cliwarngem", files: {
      "lib/app.rb" => "1",
      "spec/app_spec.rb" => "1"
    })

    stdout, _ = capture_io do
      status = RubyLean::CLI.start(["lint", dir])
      assert_equal 0, status
    end
    assert_includes stdout, "Policy passed."

    stdout, _ = capture_io do
      status = RubyLean::CLI.start(["lint", dir, "--strict"])
      assert_equal 1, status
    end
    assert_includes stdout, "Policy failed."
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_lint_json_output
    dir = create_fixture_gem("clijson", files: {
      "lib/clijson.rb" => "1"
    })

    stdout, stderr = capture_io do
      status = RubyLean::CLI.start(["lint", dir, "--format", "json"])
      assert_equal 0, status
    end

    parsed = JSON.parse(stdout)
    assert_equal "clijson", parsed["package"]["name"]
    assert_equal "1", parsed["schemaVersion"]
    assert_empty stderr
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_lint_no_archive_option
    dir = create_fixture_gem("clinoarchive", files: {
      "lib/clinoarchive.rb" => "1"
    })

    stdout, _ = capture_io do
      status = RubyLean::CLI.start(["lint", dir, "--no-archive", "--format", "json"])
      assert_equal 0, status
    end

    parsed = JSON.parse(stdout)
    assert_equal "specification", parsed["inspection"]["mode"]
    assert_equal false, parsed["inspection"]["archiveVerified"]
  ensure
    FileUtils.rm_rf(dir) if dir
  end
end
