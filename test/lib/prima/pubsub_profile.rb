require 'test_helper'

require 'stackprof'


file = 'tmp/' + File.basename(__FILE__) + '.dump'
StackProf.run(mode: :cpu, out: file) do
	require_relative 'pubsub_benchmark'
end

puts "Profile written to #{file}"