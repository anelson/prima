require 'test_helper'

require 'msgpack'

class TransformStepTest < EtlTestCase
	class TestTransformStep < TransformStep
		def process_row(row)
			if row != nil
				{"processed" => true, "row" => row}
			else
				nil
			end
		end
	end

	test "produces nothing if there are no input rows" do
		step = TestTransformStep.new
		input = []

		output = run_transform_step(input, step)

		assert_equal [], output
	end

	test "skips null values" do
		step = TestTransformStep.new
		input = [nil]

		output = run_transform_step(input, step)

		assert_equal [], output
	end
end
