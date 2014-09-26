require 'test_helper'

class CsvParserStepTest < EtlTestCase
	EXPECTED_DATA = [
		{ "line" => 2, "data" => { "col1" => "1", "col2" => "dick", "col3" => "blue" } },
		{ "line" => 3, "data" => { "col1" => "2", "col2" => "bob", "col3" => "green" } },
		{ "line" => 4, "data" => { "col1" => "3", "col2" => "phil", "col3" => "\"red" } },
	]

	EXPECTED_DATA_NO_HEADERS = EXPECTED_DATA.map { |r| 
		r = r.clone
		r['line'] -= 1
		r['data'] = [ r['data']['col1'], r['data']['col2'], r['data']['col3'] ]
		r 
	}

	COMMA_SEPARATED_NO_HEADERS = [
		{ "line" => 1, "data" => %q{"1","dick","blue"}},
		{ "line" => 2, "data" => %q{"2","bob","green"}},
		{ "line" => 3, "data" => %q{"3","phil","""red"}},
	]

	COMMA_SEPARATED_WITH_HEADERS = [
		{ "line" => 1, "data" => %q{"col1","col2","col3"}},
		{ "line" => 2, "data" => %q{"1","dick","blue"}},
		{ "line" => 3, "data" => %q{"2","bob","green"}},
		{ "line" => 4, "data" => %q{"3","phil","""red"}},
	]

	COMMA_SEPARATED_WITH_HEADERS_IMPROPER_QUOTE_ESCALE = [
		{ "line" => 1, "data" => %q{"col1","col2","col3"}},
		{ "line" => 2, "data" => %q{"1","dick","blue"}},
		{ "line" => 3, "data" => %q{"2","bob","green"}},
		{ "line" => 4, "data" => %q{"3","phil",""red"}},
	]

	test "parses comma separated values without headers" do
		step = CsvParserStep.new(header_row: false)
		input = COMMA_SEPARATED_NO_HEADERS

		output = run_transform_step(input, step)

		assert_equal EXPECTED_DATA_NO_HEADERS, output
	end

	test "parses comma separated values with headers" do
		step = CsvParserStep.new(header_row: true)
		input = COMMA_SEPARATED_WITH_HEADERS

		output = run_transform_step(input, step)

		assert_equal EXPECTED_DATA, output
	end
end
