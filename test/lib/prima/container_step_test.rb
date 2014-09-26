require 'test_helper'

require 'msgpack'

class ContainerStepTest < EtlTestCase
	class TestTransformStep < Prima::TransformStep
		def initialize(add_key, add_value)
			super()
			
			@add_key = add_key
			@add_value = add_value
		end

		def process_row(row)
			row[@add_key] = @add_value

			row
		end
	end

	def setup
		@steps = [
			TestTransformStep.new("step1", "foo"),
			TestTransformStep.new("step2", "bar"),
			TestTransformStep.new("step3", "baz"),
			TestTransformStep.new("step4", "boo"),
		]

		@input = [
			{ "line" => 1},
			{ "line" => 2},
			{ "line" => 3},
			{ "line" => 4},
		]
	end

	test "produces input at output if there are no steps" do
		step = ContainerStep.new([])
		input = @input

		output = run_transform_step(input, step)

		assert_equal @input, output
	end

	test "calls all of the steps correctly" do
		step = ContainerStep.new(@steps)
		input = @input

		output = run_transform_step(input, step)

		assert_equal [
			{ "line" => 1, "step1" => "foo", "step2" => "bar", "step3" => "baz", "step4" => "boo"},
			{ "line" => 2, "step1" => "foo", "step2" => "bar", "step3" => "baz", "step4" => "boo"},
			{ "line" => 3, "step1" => "foo", "step2" => "bar", "step3" => "baz", "step4" => "boo"},
			{ "line" => 4, "step1" => "foo", "step2" => "bar", "step3" => "baz", "step4" => "boo"},
		], output
	end
end
