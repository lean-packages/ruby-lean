# frozen_string_literal: true

require "pathname"

module RubyLean
  module Model
    class Result
      attr_reader :package, :inspection_mode, :archive_verified, :file_count, :total_bytes, :largest_files, :archive_files, :findings

      def initialize(package:, inspection_mode: "archive", archive_verified: false, file_count: 0, total_bytes: nil, largest_files: [], archive_files: nil, findings: [])
        @package = package
        @inspection_mode = inspection_mode.to_s
        @archive_verified = !!archive_verified
        @file_count = Integer(file_count)
        @total_bytes = total_bytes ? Integer(total_bytes) : nil
        @largest_files = Array(largest_files)
        @archive_files = archive_files ? Array(archive_files).map(&:to_s).sort : nil
        @findings = Array(findings).sort_by { |f| [severity_rank(f.severity), f.rule, f.paths.first || ""] }
      end

      def errors
        @findings.select(&:error?)
      end

      def warnings
        @findings.select(&:warning?)
      end

      def info_items
        @findings.select(&:info?)
      end

      def errors_count
        errors.size
      end

      def warnings_count
        warnings.size
      end

      def info_count
        info_items.size
      end

      def passed?(strict: false)
        return false if errors_count > 0
        return false if strict && warnings_count > 0

        true
      end

      def exit_code(strict: false)
        return 1 unless passed?(strict: strict)

        0
      end

      def to_h
        data = {
          "schemaVersion" => "1",
          "tool" => {
            "name" => "ruby-lean",
            "version" => RubyLean::VERSION
          },
          "package" => {
            "name" => @package.name,
            "version" => @package.version,
            "gemspec" => @package.relative_gemspec_path
          },
          "inspection" => {
            "mode" => @inspection_mode,
            "archiveVerified" => @archive_verified,
            "fileCount" => @file_count
          },
          "summary" => {
            "errors" => errors_count,
            "warnings" => warnings_count,
            "info" => info_count
          },
          "findings" => @findings.map(&:to_h)
        }

        data["inspection"]["totalBytes"] = @total_bytes if @total_bytes
        data
      end

      private

      def severity_rank(sev)
        case sev.to_s.downcase
        when "error" then 0
        when "warning" then 1
        when "info" then 2
        else 3
        end
      end
    end
  end
end
