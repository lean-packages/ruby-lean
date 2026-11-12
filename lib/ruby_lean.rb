# frozen_string_literal: true

require_relative "ruby_lean/version"
require_relative "ruby_lean/model/finding"
require_relative "ruby_lean/model/package"
require_relative "ruby_lean/model/result"
require_relative "ruby_lean/gemspec_loader"
require_relative "ruby_lean/archive_inspector"
require_relative "ruby_lean/rules/engine"
require_relative "ruby_lean/reporters/text_reporter"
require_relative "ruby_lean/reporters/json_reporter"
require_relative "ruby_lean/command/lint"
require_relative "ruby_lean/cli"

module RubyLean
  class Error < StandardError; end
  class ExecutionError < Error; end
  class GemspecLoadError < ExecutionError; end
  class BuildError < ExecutionError; end
end
