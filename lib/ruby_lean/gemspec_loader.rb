# frozen_string_literal: true

require "rubygems"
require "pathname"

module RubyLean
  class GemspecLoader
    def self.discover_and_load(target_path = ".", explicit_gemspec: nil)
      new.discover_and_load(target_path, explicit_gemspec: explicit_gemspec)
    end

    def discover_and_load(target_path = ".", explicit_gemspec: nil)
      gemspec_path = resolve_gemspec_path(target_path, explicit_gemspec)
      load_gemspec(gemspec_path)
    end

    def resolve_gemspec_path(target_path = ".", explicit_gemspec = nil)
      if explicit_gemspec
        path = File.expand_path(explicit_gemspec)
        unless File.exist?(path) && File.file?(path)
          raise ExecutionError, "Specified gemspec does not exist: #{explicit_gemspec}"
        end

        return path
      end

      target = File.expand_path(target_path || ".")

      if File.file?(target) && target.end_with?(".gemspec")
        return target
      end

      unless File.directory?(target)
        raise ExecutionError, "Target path is not a directory or gemspec: #{target_path}"
      end

      matches = Dir.glob(File.join(target, "*.gemspec"))
      if matches.empty?
        raise ExecutionError, "No .gemspec file found in #{target_path}. Specify one with --gemspec PATH"
      elsif matches.size > 1
        names = matches.map { |m| File.basename(m) }.join(", ")
        raise ExecutionError, "Multiple .gemspec files found (#{names}). Specify one with --gemspec PATH"
      end

      matches.first
    end

    def load_gemspec(gemspec_path)
      gemspec_path = File.expand_path(gemspec_path)
      gem_root = File.dirname(gemspec_path)

      source_text = File.read(gemspec_path) rescue ""
      git_dependent = detect_git_dependency(source_text)

      spec = nil
      # Evaluate gemspec in its directory context
      Dir.chdir(gem_root) do
        begin
          code = File.read(gemspec_path, mode: "r:UTF-8:-")
          spec = eval(code, binding, gemspec_path)
        rescue StandardError, ScriptError => e
          raise GemspecLoadError, "Failed to evaluate gemspec #{File.basename(gemspec_path)}: #{e.message}"
        end
      end

      if spec.nil? || !spec.is_a?(Gem::Specification)
        raise GemspecLoadError, "Failed to evaluate gemspec: #{File.basename(gemspec_path)} is invalid or empty"
      end

      spec.loaded_from = gemspec_path

      effective_files = Array(spec.files).map(&:to_s).uniq.sort

      Model::Package.new(
        name: spec.name || File.basename(gemspec_path, ".gemspec"),
        version: spec.version ? spec.version.to_s : "0.0.0",
        gemspec_path: gemspec_path,
        gem_root: gem_root,
        effective_files: effective_files,
        spec: spec,
        git_dependent: git_dependent
      )
    end

    private

    def detect_git_dependency(source)
      # Check if gemspec uses `git ls-files` or similar git command
      source.match?(/`\s*git\s+ls-files/i) ||
        source.match?(/%x\[\s*git\s+ls-files/i) ||
        source.match?(/IO\.popen\(\s*\[?['"]git['"],\s*['"]ls-files['"]/i) ||
        source.match?(/Open3\.(?:capture[23]|popen3)\(\s*['"]git\s+ls-files/i)
    end
  end
end
