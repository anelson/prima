require 'test_helper'

class TextFileInputStepTest < EtlTestCase
	test "reads zero rows from an empty text file" do
		step = Prima::TextFileInputStep.new(get_test_data_file_path('empty.txt'))

		output = run_source_step(step)

		assert_equal 0, output.length
	end

	test "preserves line endings if strip_whitespace is false" do
		step = Prima::TextFileInputStep.new(get_test_data_file_path('three_rows.txt'), strip_whitespace: false)

		output = run_source_step(step)

		assert_equal 3, output.length
		assert_equal Hash[{ "line" => 1, "data" => "row 1\n" }], output[0]
		assert_equal Hash[{ "line" => 2, "data" => "row 2\n" }], output[1]
		assert_equal Hash[{ "line" => 3, "data" => "row 3\n" }], output[2]
	end

	test "reads all rows from a non-empty text file" do
		step = Prima::TextFileInputStep.new(get_test_data_file_path('three_rows.txt'))

		output = run_source_step(step)

		assert_equal 3, output.length
		assert_equal Hash[{ "line" => 1, "data" => "row 1" }], output[0]
		assert_equal Hash[{ "line" => 2, "data" => "row 2" }], output[1]
		assert_equal Hash[{ "line" => 3, "data" => "row 3" }], output[2]
	end

	test "skips header rows if skip_header_lines" do
		step = Prima::TextFileInputStep.new(get_test_data_file_path('three_rows.txt'), skip_header_lines: 2)

		output = run_source_step(step)

		assert_equal 1, output.length
		assert_equal Hash[{ "line" => 3, "data" => "row 3" }], output[0]
	end
end
