# frozen_string_literal: true

require_relative "lib/ruby_lean/version"

Gem::Specification.new do |spec|
  spec.name          = "ruby-lean"
  spec.version       = RubyLean::VERSION
  spec.authors       = ["lean-packages contributors"]
  spec.email         = ["maintainers@lean-packages.org"]

  spec.summary       = "Audits RubyGem distribution contents using native RubyGems packaging rules"
  spec.description   = "A Ruby-native CLI to audit RubyGem package distributions, detect unnecessary files, and inspect archive contents."
  spec.homepage      = "https://github.com/lean-packages/ruby-lean"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Explicit lean file list: only lib, exe, and core documentation
  spec.files = Dir["lib/**/*.rb"] + ["exe/ruby-lean", "LICENSE.md", "README.md", "CHANGELOG.md"]
  spec.bindir = "exe"
  spec.executables = ["ruby-lean"]
  spec.require_paths = ["lib"]
end
