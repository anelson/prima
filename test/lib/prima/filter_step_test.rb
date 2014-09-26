require 'test_helper'

class FilterStepTest < EtlTestCase
	test "passes all objects if the filter function returns true" do
		step = FilterStep.new lambda { |row| true }
		input = ['blah', 'foo', 'whee']

		output = run_transform_step(input, step)

		assert_equal input, output
	end

	test "passes no objects if the filter function returns false" do
		step = FilterStep.new lambda { |row| false }
		input = ['blah', 'foo', 'whee']

		output = run_transform_step(input, step)

		assert_equal [], output
	end

	test "passes some objects if the filter function is picky" do
		step = FilterStep.new lambda { |row| row.include? 'h' }
		input = ['blah', 'foo', 'whee']

		output = run_transform_step(input, step)

		assert_equal ['blah', 'whee'], output
	end
end
