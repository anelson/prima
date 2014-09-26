require 'test_helper'

require 'msgpack'

class SourceStepTest < EtlTestCase
	class TestSourceStep < SourceStep
		attr_accessor :input_rows

		def initialize
			super

			@input_rows = []
		end

		def before_run
			@incoming = input_rows
		end

		def process_row(row)
			if row != nil
				{"processed" => true, "row" => row}
			else
				nil
			end
		end
	end

	def setup
		@row = {"a string" => "bar", "an int" => 2, "a float" => 1.0/3.0, "an array" => [1, 2, 3, "4", 5.0], "a hash" => { "x" => 1, "y" => 2, 3 => 4}}
	end


	test "produces output in MessagePack format" do
		step = TestSourceStep.new
		step.input_rows = [@row]

		output = run_source_step(step)

		assert_equal [ Hash["processed" => true, "row" => @row ] ], output
	end

	test "supports serializing all the necessary Ruby types" do
		# Exercise the serializing of some extra Ruby types that msgpack doesn't itself handle, and that EtlStep doesn't handle very well
		row = @row

		row["a decimal"] = BigDecimal(1.5, 10)
		row["a datetime"] = DateTime.now
		row["a date"] = Date.today
		row["a time"] = Time.now

		step = TestSourceStep.new
		step.input_rows = [@row]

		output = run_source_step(step)

		#Due to msgpack limitations, output will not match row exactly, because decimal is serialized as float
		assert_equal row["a decimal"], output[0]["row"]["a decimal"]
		assert_equal row["a datetime"].to_s, output[0]["row"]["a datetime"]
		assert_equal row["a date"].to_s, output[0]["row"]["a date"]
		assert_equal row["a time"].to_s, output[0]["row"]["a time"]
	end
end
