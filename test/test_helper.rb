# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "tmpdir"
require "json"
require "open3"

require_relative "../lib/ruby_lean"

module TestHelper
  def create_fixture_gem(name, files: {}, gemspec_body: nil)
    dir = Dir.mktmpdir("ruby-lean-fixture-#{name}-")

    files.each do |path, content|
      full_path = File.join(dir, path)
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, content)
    end

    gemspec_content = gemspec_body || <<-RUBY
      Gem::Specification.new do |s|
        s.name = "#{name}"
        s.version = "1.0.0"
        s.summary = "Summary for #{name}"
        s.authors = ["Test Author"]
        s.license = "MIT"
        s.files = #{files.keys.inspect}
      end
    RUBY

    gemspec_path = File.join(dir, "#{name}.gemspec")
    File.write(gemspec_path, gemspec_content)

    dir
  end
end

class Minitest::Test
  include TestHelper
end
