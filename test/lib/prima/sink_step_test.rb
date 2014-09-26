require 'test_helper'

require 'msgpack'

class SinkStepTest < EtlTestCase
	class TestSinkStep < SinkStep
		attr_accessor :received_rows

		def before_run
			@received_rows = []
		end

		def process_row(row)
			@received_rows << row

			nil
		end

		def handle_output(row)
		end
	end

	def setup
		@row = {"a string" => "bar", "an int" => 2, "a float" => 1.0/3.0, "an array" => [1, 2, 3, "4", 5.0], "a hash" => { "x" => 1, "y" => 2, 3 => 4}}
	end

	test "processes input in MessagePack format" do
		step = TestSinkStep.new

		run_sink_step [@row], step

		assert_equal [@row], step.received_rows
	end

	test "supports serializing all the necessary Ruby types" do
		# Exercise the serializing of some extra Ruby types that msgpack doesn't itself handle, and that EtlStep doesn't handle very well
		row = @row

		row["a decimal"] = BigDecimal(1.5, 10)
		row["a datetime"] = DateTime.now
		row["a date"] = Date.today
		row["a time"] = Time.now

		step = TestSinkStep.new

		run_sink_step [@row], step

		#Due to msgpack limitations, result will not match row exactly, because decimal is serialized as float
		assert_equal 1, step.received_rows.length
		assert_equal row["a decimal"], step.received_rows[0]["a decimal"]
		assert_equal row["a datetime"].to_s, step.received_rows[0]["a datetime"]
		assert_equal row["a date"].to_s, step.received_rows[0]["a date"]
		assert_equal row["a time"].to_s, step.received_rows[0]["a time"]
	end
end
