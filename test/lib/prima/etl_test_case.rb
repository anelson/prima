class EtlTestCase < ActiveSupport::TestCase
	def get_test_data_file_path(filename)
		File.dirname(__FILE__) + '/testdata/' + filename
	end

	def teardown
		begin
			ActiveRecord::Base.connection_pool.disconnect!
		rescue ActiveRecord::ConnectionNotEstablished
			# This is fine if ActiveRecord isn't in use
		end
	end

	def setup
		begin
  		ActiveRecord::Base.connection.reconnect!
		rescue ActiveRecord::ConnectionNotEstablished
			# This is fine if ActiveRecord isn't in use
		end

		# Quiet the logger
		Prima.configure do |config|
			config.logger.level = Logger::WARN
			config.benchmarking = true
		end
  end

	#Runs a source step, assuming the step has its own input.  Takes msgpack-serialized output objects
	#deserializing them and returns an array containing the output
	def run_source_step(step)
		outgoing_stream = StringIO.new("", 'w')
		step.outgoing = outgoing_stream

		run_step step

		outgoing_stream.reopen(outgoing_stream.string, 'r')
		output_unpacker = MessagePack::Unpacker.new(outgoing_stream)
		output = []
		output_unpacker.each do |row|
			output << row
		end

		output
	end

	#Runs a sink step, assuming the step has its own output.  Takes an input array of objects,
	#and writes them to the step's incoming stream in msgpack format
	def run_sink_step(input, step)
		incoming_stream = StringIO.new("", 'w')

		input_packer = MessagePack::Packer.new(incoming_stream)
		input.each do |i|
			input_packer.write(i).flush
		end

		incoming_stream.reopen(incoming_stream.string, 'r')
		step.incoming = incoming_stream

		run_step step
	end

	#Runs a transform step, passing the input array of objects, serialized as msgpack format,
	#and returning an array containing the deserialzied output of the transform
	def run_transform_step(input, step)
		incoming_stream = StringIO.new("", 'w')

		input_packer = MessagePack::Packer.new(incoming_stream)
		input.each do |i|
			input_packer.write(i).flush
		end

		incoming_stream.reopen(incoming_stream.string, 'r')
		step.incoming = incoming_stream

		outgoing_stream = StringIO.new("", 'w')
		step.outgoing = outgoing_stream

		run_step step

		outgoing_stream.reopen(outgoing_stream.string, 'r')
		output_unpacker = MessagePack::Unpacker.new(outgoing_stream)
		output = []
		output_unpacker.each do |row|
			output << row
		end

		output
	end

	def run_step(step)
		step.shared_data = {}

		step.run
	end
end
