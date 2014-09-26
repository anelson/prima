require_relative '../../test_helper'

class VersionTest < MiniTest::Unit::TestCase
	def test_version_defined
		refute_nil Prima::VERSION
	end
end
