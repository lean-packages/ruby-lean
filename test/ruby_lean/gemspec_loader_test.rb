# frozen_string_literal: true

require_relative "../test_helper"

class GemspecLoaderTest < Minitest::Test
  def test_discover_and_load_single_gemspec_in_dir
    dir = create_fixture_gem("testgem", files: { "lib/testgem.rb" => "module TestGem; end" })
    package = RubyLean::GemspecLoader.discover_and_load(dir)

    assert_equal "testgem", package.name
    assert_equal "1.0.0", package.version
    assert_includes package.effective_files, "lib/testgem.rb"
    refute package.git_dependent
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_load_explicit_gemspec_path
    dir = create_fixture_gem("explicit", files: { "lib/explicit.rb" => "module Explicit; end" })
    gemspec_file = File.join(dir, "explicit.gemspec")

    package = RubyLean::GemspecLoader.discover_and_load(explicit_gemspec: gemspec_file)

    assert_equal "explicit", package.name
    assert_equal gemspec_file, package.gemspec_path
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_discover_fails_when_no_gemspec_found
    Dir.mktmpdir do |empty_dir|
      err = assert_raises(RubyLean::ExecutionError) do
        RubyLean::GemspecLoader.discover_and_load(empty_dir)
      end
      assert_match(/No \.gemspec file found/i, err.message)
    end
  end

  def test_discover_fails_when_multiple_gemspecs_found
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "one.gemspec"), "Gem::Specification.new { |s| s.name = 'one'; s.version = '1.0'; s.summary = 's'; s.authors = ['a'] }")
      File.write(File.join(dir, "two.gemspec"), "Gem::Specification.new { |s| s.name = 'two'; s.version = '1.0'; s.summary = 's'; s.authors = ['a'] }")

      err = assert_raises(RubyLean::ExecutionError) do
        RubyLean::GemspecLoader.discover_and_load(dir)
      end
      assert_match(/Multiple \.gemspec files found/i, err.message)
    end
  end

  def test_git_dependent_detection
    gemspec_body = <<-RUBY
      Gem::Specification.new do |s|
        s.name = "gitgem"
        s.version = "1.0.0"
        s.summary = "Git gem"
        s.authors = ["Jane"]
        s.files = `git ls-files -z 2>/dev/null`.split("\x0")
      end
    RUBY

    dir = create_fixture_gem("gitgem", files: { "lib/gitgem.rb" => "1" }, gemspec_body: gemspec_body)
    package = RubyLean::GemspecLoader.discover_and_load(dir)

    assert package.git_dependent
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_invalid_syntax_gemspec
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "broken.gemspec"), "syntax error here !!! :::")

      err = assert_raises(RubyLean::GemspecLoadError) do
        RubyLean::GemspecLoader.discover_and_load(dir)
      end
      assert_match(/Failed to evaluate gemspec/i, err.message)
    end
  end
end
