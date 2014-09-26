require 'test_helper'

require 'stackprof'

class DevNull
	def close; nil; end
	def puts(x); nil; end
	def write(x); nil; end
	def binmode; nil; end
end

class DummyIOGenerator < DevNull
	def initialize(iterations, block)
		@iterations = iterations
		@block = block
	end

	def each
		@iterations.times do
			yield @block.call
		end
	end
end

class TestStringGenerator < DummyIOGenerator
	def initialize(iterations)
		super(iterations, lambda { "TEST STRING "})
	end
end

class TestObjectGenerator < DummyIOGenerator
	def initialize(iterations)
		super(iterations, lambda { { "foo" => bar, "baz" => 5 } })
	end
end

module StepProfiler
	def run
		file = "tmp/step_#{self.class.name}.dump"
		StackProf.run(mode: :cpu, out: file) do
			super
		end

		puts "Profiled step at #{file}"
	end
end

class SourceEtlStep < Prima::SourceStep
	include StepProfiler

	def initialize(input)
		super()

		@input = input
	end

	def before_run(step)
		@incoming = @input
	end
end

# A step that does some nominal processing on an object, returning a different object as a result
class TransformEtlStep < Prima::TransformStep
	include StepProfiler
	
	def process_row(x) 
		{ :processed => true, :row => x}
	end
end

class NullStep < Prima::NullStep
	include StepProfiler	
end

class EtlStepProfile < EtlTestCase
	ITERATION_COUNT = 1000000

	def setup
		super

		if defined?(Rodimus)
			Rodimus.configure do |config|
				config.logger.level = Logger::WARN
			end
		end
	end

	test "profile raw throughput assuming no I/O" do
		times = ::Benchmark.measure do
			file = 'tmp/transformation_no_io_transform.dump'
			StackProf.run(mode: :cpu, out: file) do
				t = Prima::Transformation.new
				
				source = SourceEtlStep.new(TestStringGenerator.new(ITERATION_COUNT))
				t.add_step source

				transform = TransformEtlStep.new
				t.add_step transform

				sink = NullStep.new
				t.add_step sink
				
				t.run
			end

			puts "Profiled parent process at #{file}"
		end

		puts "ETL source/sink with no I/O: #{ITERATION_COUNT} rows in #{times.real} seconds; #{ITERATION_COUNT / times.real} rows/sec"
	end
end
