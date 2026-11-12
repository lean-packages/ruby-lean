# frozen_string_literal: true

module RubyLean
  module Reporters
    class TextReporter
      def self.render(result, strict: false, quiet: false)
        new(result, strict: strict, quiet: quiet).render
      end

      def initialize(result, strict: false, quiet: false)
        @result = result
        @strict = strict
        @quiet = quiet
      end

      def render
        lines = []

        unless @quiet
          lines << "ruby-lean lint: #{@result.package.name} #{@result.package.version}"
          lines << "  Gemspec:     #{@result.package.relative_gemspec_path}"
          mode_label = @result.archive_verified ? "Archive verified (.gem)" : "Specification-only (--no-archive)"
          lines << "  Mode:        #{mode_label}"
          lines << "  Files:       #{@result.file_count}"
          if @result.total_bytes
            lines << "  Total size:  #{format_bytes(@result.total_bytes)}"
          end
          lines << ""
        end

        if @result.findings.empty?
          lines << "No issues found. Gem packaging passes policy."
          lines << "Policy passed."
        else
          # Group findings by severity
          errors = @result.errors
          warnings = @result.warnings
          info = @result.info_items

          if errors.any?
            lines << "ERRORS (#{errors.size}):"
            errors.each { |f| lines.concat(format_finding(f)) }
            lines << ""
          end

          if warnings.any?
            lines << "WARNINGS (#{warnings.size}):"
            warnings.each { |f| lines.concat(format_finding(f)) }
            lines << ""
          end

          if info.any?
            lines << "INFO (#{info.size}):"
            info.each { |f| lines.concat(format_finding(f)) }
            lines << ""
          end

          summary_text = "Summary: #{@result.errors_count} error(s), #{@result.warnings_count} warning(s)"
          summary_text += " (strict mode enabled)" if @strict
          lines << summary_text

          if @result.passed?(strict: @strict)
            lines << "Policy passed."
          else
            lines << "Policy failed."
          end
        end

        lines.join("\n")
      end

      private

      def format_finding(finding)
        out = []
        out << "  [#{finding.rule}] #{finding.message}"
        finding.paths.each do |p|
          out << "    - #{p}"
        end
        if finding.suggested_action
          out << "    Suggested action: #{finding.suggested_action}"
        end
        out
      end

      def format_bytes(bytes)
        if bytes < 1024
          "#{bytes} B"
        elsif bytes < 1024 * 1024
          "#{(bytes / 1024.0).round(1)} KB (#{bytes} bytes)"
        else
          "#{(bytes / (1024.0 * 1024.0)).round(2)} MB (#{bytes} bytes)"
        end
      end
    end
  end
end
