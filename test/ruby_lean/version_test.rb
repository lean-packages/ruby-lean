# frozen_string_literal: true

require_relative "../test_helper"

class VersionTest < Minitest::Test
  def test_version_is_defined
    refute_nil RubyLean::VERSION
    assert_match(/^\d+\.\d+\.\d+/, RubyLean::VERSION)
  end
end
