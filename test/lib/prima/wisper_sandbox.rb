require 'test_helper'

require 'benchmark'

require 'wisper'

class WisperSandbox < MiniTest::Unit::TestCase
	ITERATIONS = 1000000

	module MyWisper
		include Wisper::Publisher

		def broadcast(event, *args)
      local_registrations.each do | registration |
        registration.broadcast(clean_event(event), self, *args)
      end
    end
	end

	class Publisher
		include Wisper::Publisher

		def increment
			publish(:plusone)
		end
	end

	class Subscriber
		attr_reader :count

		def initialize
			@count = 0
		end

		def plusone
			@count += 1
		end
	end

	class MyPublisher
		include Prima::Publisher

		def increment
			publish(:plusone)
		end
	end

	class MySubscriber
		include Prima::Subscriber

		attr_reader :count

		def initialize
			@count = 0
		end

		def plusone
			@count += 1
		end
	end

	def test_how_fast_is_wisper
		times = Benchmark.measure do 
			pub = MyPublisher.new
			sub = MySubscriber.new

			pub.subscribe sub

			ITERATIONS.times do 
				pub.increment
			end

			assert_equal ITERATIONS, sub.count
		end

		puts "My variant, With a subscriber: Published #{ITERATIONS} in #{times.real}; that's #{ITERATIONS/times.real}/second!"

		times = Benchmark.measure do 
			pub = MyPublisher.new

			ITERATIONS.times do 
				pub.increment
			end
		end

		puts "My variant, Without a subscriber: Published #{ITERATIONS} in #{times.real}; that's #{ITERATIONS/times.real}/second!"

		times = Benchmark.measure do 
			pub = Publisher.new
			sub = Subscriber.new

			pub.subscribe sub

			ITERATIONS.times do 
				pub.increment
			end

			assert_equal ITERATIONS, sub.count
		end

		puts "With a subscriber: Published #{ITERATIONS} in #{times.real}; that's #{ITERATIONS/times.real}/second!"

		times = Benchmark.measure do 
			pub = Publisher.new

			ITERATIONS.times do 
				pub.increment
			end
		end

		puts "Without a subscriber: Published #{ITERATIONS} in #{times.real}; that's #{ITERATIONS/times.real}/second!"
	end
end