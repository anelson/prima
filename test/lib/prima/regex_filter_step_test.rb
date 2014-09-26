require 'test_helper'

class RegexFilterStepTest < EtlTestCase
	test "passes all objects if the regex matches everything" do
		step = RegexFilterStep.new /.*/
		input = [
			{ 'data' => 'blah' },
			{ 'data' => 'foo' },
			{ 'data' => 'whee' }
		]

		output = run_transform_step(input, step)

		assert_equal input, output
	end

	test "passes no objects if the regex matces nothing" do
		step = RegexFilterStep.new /[0-9]+/
		input = [
			{ 'data' => 'blah' },
			{ 'data' => 'foo' },
			{ 'data' => 'whee' }
		]

		output = run_transform_step(input, step)

		assert_equal [], output
	end

	test "passes some objects if the filter function is picky" do
		step = RegexFilterStep.new /ee/
		input = [
			{ 'data' => 'blah' },
			{ 'data' => 'foo' },
			{ 'data' => 'whee' },
			{ 'data' => 'wheel' }
		]

		output = run_transform_step(input, step)

		assert_equal [
			{ 'data' => 'ee' },
			{ 'data' => 'ee' } ], output
	end

	test "replace input with capture group if present" do 
		step = RegexFilterStep.new /^\"(.+)\"$/
		input = [
			{ "line" => 1, "data" => %q{"1","dick","blue"} },
			{ "line" => 2, "data" => %q{"2","bob","green"} },
			{ "line" => 3, "data" => %q{"3","phil","""red"} }
		]

		output = run_transform_step(input, step)

		assert_equal [
			{ "line" => 1, "data" => %q{1","dick","blue} },
			{ "line" => 2, "data" => %q{2","bob","green} },
			{ "line" => 3, "data" => %q{3","phil","""red} } ], output
	end

	test "replace input with named values if named capture groups are used" do 
		step = RegexFilterStep.new /(?<num1>\d):(?<num2>\d):(?<num3>\d)/
		input = [
			{ 'line' => 1, 'data' => '1:2:3' },
			{ 'line' => 2, 'data' => 'foo' },
			{ 'line' => 3, 'data' => 'whee' },
			{ 'line' => 4, 'data' => 'wheel' }
		]

		output = run_transform_step(input, step)

		assert_equal [
			{ "line" => 1, "data" => { 'num1' => '1', 'num2' => '2', 'num3' => '3' } }
			], output
	end
end
