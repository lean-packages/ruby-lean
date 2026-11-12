# frozen_string_literal: true

require_relative "../test_helper"

class IntegrationTest < Minitest::Test
  EXE_PATH = File.expand_path("../../exe/ruby-lean", __dir__)

  def test_executable_help
    stdout, stderr, status = Open3.capture3(EXE_PATH, "--help")

    assert_equal 0, status.exitstatus
    assert_includes stdout, "Usage: ruby-lean lint"
    assert_empty stderr
  end

  def test_executable_version
    stdout, stderr, status = Open3.capture3(EXE_PATH, "--version")

    assert_equal 0, status.exitstatus
    assert_includes stdout, "ruby-lean #{RubyLean::VERSION}"
    assert_empty stderr
  end

  def test_project_files_remain_unchanged
    dir = create_fixture_gem("intclean", files: {
      "lib/intclean.rb" => "module IntClean; end\n",
      "README.md" => "# IntClean\n"
    })

    initial_files = Dir.glob(File.join(dir, "**/*"), File::FNM_DOTMATCH).sort

    stdout, stderr, status = Open3.capture3(EXE_PATH, "lint", dir)

    assert_equal 0, status.exitstatus
    assert_includes stdout, "Policy passed."
    assert_empty stderr

    post_files = Dir.glob(File.join(dir, "**/*"), File::FNM_DOTMATCH).sort
    assert_equal initial_files, post_files, "Target project directory was modified by lint execution"
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_self_lint_passes_strict
    repo_root = File.expand_path("../..", __dir__)
    stdout, stderr, status = Open3.capture3(EXE_PATH, "lint", repo_root, "--strict")

    assert_equal 0, status.exitstatus, "Self-lint failed with output: #{stdout} #{stderr}"
    assert_includes stdout, "ruby-lean lint: ruby-lean #{RubyLean::VERSION}"
    assert_includes stdout, "Policy passed."
  end
end
