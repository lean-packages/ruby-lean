# frozen_string_literal: true

module RubyLean
  module Model
    class Finding
      SEVERITIES = %w[error warning info].freeze

      attr_reader :rule, :severity, :message, :paths, :suggested_action

      def initialize(rule:, severity:, message:, paths: [], suggested_action: nil)
        @rule = rule.to_s
        @severity = severity.to_s.downcase
        @message = message.to_s
        @paths = Array(paths).map(&:to_s).sort
        @suggested_action = suggested_action&.to_s
      end

      def error?
        @severity == "error"
      end

      def warning?
        @severity == "warning"
      end

      def info?
        @severity == "info"
      end

      def to_h
        data = {
          "rule" => @rule,
          "severity" => @severity,
          "message" => @message,
          "paths" => @paths
        }
        data["suggestedAction"] = @suggested_action if @suggested_action
        data
      end

      def ==(other)
        other.is_a?(Finding) &&
          rule == other.rule &&
          severity == other.severity &&
          message == other.message &&
          paths == other.paths &&
          suggested_action == other.suggested_action
      end
    end
  end
end
