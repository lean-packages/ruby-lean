# frozen_string_literal: true

module RubyLean
  module Model
    class Package
      attr_reader :name, :version, :gemspec_path, :gem_root, :effective_files, :spec, :git_dependent

      def initialize(name:, version:, gemspec_path:, gem_root:, effective_files: [], spec: nil, git_dependent: false)
        @name = name.to_s
        @version = version.to_s
        @gemspec_path = gemspec_path.to_s
        @gem_root = File.expand_path(gem_root.to_s)
        @effective_files = Array(effective_files).map(&:to_s).uniq.sort
        @spec = spec
        @git_dependent = !!git_dependent
      end

      def relative_gemspec_path
        Pathname.new(@gemspec_path).relative_path_from(Pathname.new(@gem_root)).to_s
      rescue ArgumentError
        @gemspec_path
      end
    end
  end
end
