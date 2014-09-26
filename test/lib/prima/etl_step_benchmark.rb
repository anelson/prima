require 'test_helper'

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

class SourceEtlStep < Prima::SourceStep
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
	def process_row(x) 
		{ :processed => true, :row => x}
	end
end

class EtlStepBenchmark < EtlTestCase
	ITERATION_COUNT = 1000000

	def setup
		super

		if defined?(Rodimus)
			Rodimus.configure do |config|
				config.logger.level = Logger::WARN
			end
		end
	end

	test "benchmark raw throughput assuming no I/O" do
		times = ::Benchmark.measure do
			t = Prima::Transformation.new
			
			source = SourceEtlStep.new(TestStringGenerator.new(ITERATION_COUNT))
			t.add_step source

			transform = TransformEtlStep.new
			t.add_step transform

			sink = Prima::NullStep.new
			t.add_step sink
			
			t.run
		end

		puts "ETL source/sink with no I/O: #{ITERATION_COUNT} rows in #{times.real} seconds; #{ITERATION_COUNT / times.real} rows/sec"

		if defined?(Rodimus)
			times = ::Benchmark.measure do
				# Make a transform with three steps, the first one hooked up to an object generator,
				# the last one writing out to nothing, and the one in between just outputting the object it's given
				t = Rodimus::Transformation.new

				source = Rodimus::Step.new
				source.incoming = TestStringGenerator.new(ITERATION_COUNT)
				t.steps << source

				transform = Rodimus::Step.new
				t.steps << transform

				sink = Rodimus::Step.new
				sink.outgoing = DevNull.new
				t.steps << sink
				
				t.run
			end

			puts "Rodiumus source/sink with no I/O: #{ITERATION_COUNT} rows in #{times.real} seconds; #{ITERATION_COUNT / times.real} rows/sec"
		end
	end
end
