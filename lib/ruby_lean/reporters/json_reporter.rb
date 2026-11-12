# frozen_string_literal: true

require "json"

module RubyLean
  module Reporters
    class JsonReporter
      def self.render(result)
        new(result).render
      end

      def initialize(result)
        @result = result
      end

      def render
        JSON.pretty_generate(@result.to_h)
      end
    end
  end
end
