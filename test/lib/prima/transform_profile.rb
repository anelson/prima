require 'test_helper'

BIG_FILE_NAME = 'tmp/bigfile.csv'
BIG_FILE_LINES = 800000

Prima.configure do |config|
	config.logger.level = Logger::WARN
	config.benchmarking = true
end

def text_file_input_only
	profiler = Prima::StepProfiler.new 'tmp/transform'
	times = Benchmark.measure do
		t = Prima::Transformation.new

		input = Prima::TextFileInputStep.new BIG_FILE_NAME
		input.subscribe(profiler) if profiler != nil
		t.add_step input

		null = Prima::NullStep.new
		null.subscribe(profiler) if profiler != nil
		t.add_step null
		
	 	t.run
	end

	puts "#{BIG_FILE_LINES} lines processed in #{times.real} seconds; #{BIG_FILE_LINES / times.real} lines/sec"
end

def text_file_input_raw_pipes
	File.open(BIG_FILE_NAME, 'r') do |file|
		read, write = IO.pipe
		read.sync = true
		read.binmode
		write.sync = true
		write.binmode

		childid = fork {
			StackProf.run mode: :cpu, out: 'tmp/raw_input_child_process.dump' do 
				buffer = '\0' * Prima::MsgpackIoReader::BUFFER_SIZE
				write.close
				count = 0

				eof = false
				while !eof
					begin
						data = read.sysread(Prima::MsgpackIoReader::BUFFER_SIZE, buffer)
					rescue EOFError
						#End of the stream
						eof = true
					end
				end
				read.close
			end
		}

		read.close
		StackProf.run mode: :cpu, out: 'tmp/raw_input_parent_process.dump' do 
			times = Benchmark.measure do
				file.each do |line|
					write.syswrite line
				end

				write.close

				Process.waitall
			end

			puts "#{BIG_FILE_LINES} lines processed in #{times.real} seconds; #{BIG_FILE_LINES / times.real} lines/sec"
		end
	end

end

# text_file_input_only
text_file_input_raw_pipes