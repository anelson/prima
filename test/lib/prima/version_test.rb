require_relative '../../test_helper'

class VersionTest < MiniTest::Test
	def test_version_defined
		refute_nil Prima::VERSION
	end
end
