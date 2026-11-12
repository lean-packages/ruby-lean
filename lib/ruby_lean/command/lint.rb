# frozen_string_literal: true

module RubyLean
  module Command
    class Lint
      def self.run(options = {})
        new(options).run
      end

      def initialize(options = {})
        @options = options
        @target_path = options[:path] || "."
        @explicit_gemspec = options[:gemspec]
        @format = (options[:format] || "text").to_s.downcase
        @strict = !!options[:strict]
        @archive = options.fetch(:archive, true)
        @quiet = !!options[:quiet]
      end

      def run
        package = GemspecLoader.discover_and_load(@target_path, explicit_gemspec: @explicit_gemspec)

        result = if @archive
                   inspect_with_archive(package)
                 else
                   inspect_specification_only(package)
                 end

        output = render_result(result)

        if @format == "json"
          puts output
        else
          puts output unless output.empty?
        end

        result.exit_code(strict: @strict)
      end

      private

      def inspect_with_archive(package)
        archive_data = nil
        build_error_finding = nil

        begin
          archive_data = ArchiveInspector.inspect_package(package)
        rescue BuildError => e
          build_error_finding = Model::Finding.new(
            rule: "RUBYLEAN_BUILD_ERROR",
            severity: "error",
            message: "Failed to build .gem archive: #{e.message}",
            paths: [package.relative_gemspec_path],
            suggested_action: "Fix gemspec errors or build issues reported by RubyGems."
          )
        end

        if archive_data
          findings = Rules::Engine.audit(package, archive_files: archive_data.archive_files)
          Model::Result.new(
            package: package,
            inspection_mode: "archive",
            archive_verified: true,
            file_count: archive_data.file_count,
            total_bytes: archive_data.total_bytes,
            largest_files: archive_data.largest_files,
            archive_files: archive_data.archive_files,
            findings: findings
          )
        else
          # Fallback to spec rules plus build error finding
          findings = Rules::Engine.audit(package, archive_files: nil)
          findings << build_error_finding if build_error_finding

          Model::Result.new(
            package: package,
            inspection_mode: "archive",
            archive_verified: false,
            file_count: package.effective_files.size,
            total_bytes: calculate_disk_bytes(package),
            findings: findings
          )
        end
      end

      def inspect_specification_only(package)
        findings = Rules::Engine.audit(package, archive_files: nil)

        Model::Result.new(
          package: package,
          inspection_mode: "specification",
          archive_verified: false,
          file_count: package.effective_files.size,
          total_bytes: calculate_disk_bytes(package),
          findings: findings
        )
      end

      def calculate_disk_bytes(package)
        total = 0
        package.effective_files.each do |rel_path|
          full_path = File.join(package.gem_root, rel_path)
          total += File.size(full_path) if File.file?(full_path)
        end
        total
      rescue StandardError
        nil
      end

      def render_result(result)
        case @format
        when "json"
          Reporters::JsonReporter.render(result)
        else
          Reporters::TextReporter.render(result, strict: @strict, quiet: @quiet)
        end
      end
    end
  end
end
