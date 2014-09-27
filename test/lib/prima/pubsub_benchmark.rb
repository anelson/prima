require 'test_helper'
require 'benchmark'

ITERATION_COUNT = 1000000

class MyPublisher
	include Prima::Publisher

	def increment
		publish :plus_one
	end
end

class MySubscriber
	include Prima::Subscriber

	attr_reader :count

	def plus_one
		@count ||= 0
		@count += 1
	end
end

=begin

puts "Calling a method on a class directly: "
times = ::Benchmark.measure do
	sub = MySubscriber.new

	ITERATION_COUNT.times do 
		sub.plus_one
	end

	raise "fail" unless sub.count == ITERATION_COUNT
end

puts "  #{ITERATION_COUNT} calls in #{times.real} seconds.  #{ITERATION_COUNT/times.real} calls/sec"

puts "Calling a method on a class using send: "
times = ::Benchmark.measure do
	sub = MySubscriber.new

	ITERATION_COUNT.times do 
		sub.send :plus_one
	end

	raise "fail" unless sub.count == ITERATION_COUNT
end

puts "  #{ITERATION_COUNT} calls in #{times.real} seconds.  #{ITERATION_COUNT/times.real} calls/sec"


puts "Publisher with no subscribers: "
times = ::Benchmark.measure do
	pub = MyPublisher.new

	ITERATION_COUNT.times do 
		pub.increment
	end
end

puts "  #{ITERATION_COUNT} pubs in #{times.real} seconds.  #{ITERATION_COUNT/times.real} pubs/sec"

=end 

puts "Publisher with one subscriber: "
times = ::Benchmark.measure do
	pub = MyPublisher.new
	sub = MySubscriber.new

	pub.subscribe sub

	ITERATION_COUNT.times do 
		pub.increment
	end

	raise "fail" unless sub.count == ITERATION_COUNT
end

puts "  #{ITERATION_COUNT} pubs in #{times.real} seconds.  #{ITERATION_COUNT/times.real} pubs/sec"


=begin
puts "Publisher with two subscribers: "
times = ::Benchmark.measure do
	pub = MyPublisher.new
	sub1 = MySubscriber.new
	sub2 = MySubscriber.new

	pub.subscribe sub1
	pub.subscribe sub2

	ITERATION_COUNT.times do 
		pub.increment
	end

	raise "fail" unless sub1.count == ITERATION_COUNT
	raise "fail" unless sub2.count == ITERATION_COUNT
end

puts "  #{ITERATION_COUNT} pubs in #{times.real} seconds.  #{ITERATION_COUNT/times.real} pubs/sec"

=end