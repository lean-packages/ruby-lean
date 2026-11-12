# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "lib" << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

desc "Lint repository with ruby-lean"
task :lint do
  require_relative "lib/ruby_lean"
  status = RubyLean::CLI.start(["lint", "--strict"])
  exit(status) if status != 0
end

desc "Build ruby-lean gem package"
task :build do
  sh "gem build ruby-lean.gemspec"
end

task default: %i[test lint]
