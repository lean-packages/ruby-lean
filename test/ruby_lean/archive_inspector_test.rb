# frozen_string_literal: true

require_relative "../test_helper"

class ArchiveInspectorTest < Minitest::Test
  def test_inspect_package_builds_and_reads_archive
    dir = create_fixture_gem("archtest", files: {
      "lib/archtest.rb" => "module ArchTest; end\n",
      "README.md" => "# ArchTest\n"
    })

    package = RubyLean::GemspecLoader.discover_and_load(dir)
    archive_data = RubyLean::ArchiveInspector.inspect_package(package)

    assert_equal 2, archive_data.file_count
    assert_includes archive_data.archive_files, "lib/archtest.rb"
    assert_includes archive_data.archive_files, "README.md"
    assert archive_data.total_bytes > 0
    assert_equal 2, archive_data.largest_files.size

    # Ensure no .gem file was left in fixture directory
    gem_files = Dir.glob(File.join(dir, "*.gem"))
    assert_empty gem_files, "Temporary .gem was not cleaned up from the project directory"
  ensure
    FileUtils.rm_rf(dir) if dir
  end

  def test_inspect_package_handles_build_failure
    dir = create_fixture_gem("brokenbuild", files: {
      "lib/exists.rb" => "1"
    }, gemspec_body: <<-RUBY)
      Gem::Specification.new do |s|
        s.name = "brokenbuild"
        s.version = "1.0.0"
        s.summary = "summary"
        s.authors = ["Jane"]
        s.files = ["lib/exists.rb", "lib/missing_file.rb"]
      end
    RUBY

    package = RubyLean::GemspecLoader.discover_and_load(dir)

    assert_raises(RubyLean::BuildError) do
      RubyLean::ArchiveInspector.inspect_package(package)
    end
  ensure
    FileUtils.rm_rf(dir) if dir
  end
end
