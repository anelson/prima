require 'test_helper'

require 'msgpack'

class EventMachineExperimentTest < EtlTestCase
	MB = 1024.0 * 1024.0
	LINES = 800000
	LINE = %q{"0101000000020","01","16 SE 2ND STREET LLC","","","16 SE 2ND STREET LLC","","505 PARK AVE #18 FL","NEW YORK","NY","10022","USA","16 SE 2 ST","16","SE","2","","ST","","","Miami","33131-2103","2865","6401","0.00","60198.00","1.3820","0","0.00","0","0","0","0","0","0","0101","2014","15049500","0","6789","15056289","0","0","0","0","0","0","0","0","0","0","15056289","0","15056289","0","15056289","0","15056289","0","15056289","2013","5718810","0","6789","5725599","0","0","0","0","0","0","0","0","0","0","5725599","0","5725599","0","5725599","0","5725599","0","5725599","2012","5718810","0","8764","5727574","0","0","0","0","0","0","0","0","0","0","5727574","0","5727574","0","5727574","0","5727574","0","5727574"}
	SIZE = LINE.length * LINES

	def setup
		begin
			ActiveRecord::Base.connection_pool.disconnect!
		rescue ActiveRecord::ConnectionNotEstablished
			# This is fine if ActiveRecord isn't in use
		end
	end

	test "how fast is Ruby native IO reads" do
		#path = get_test_data_file_path('parcel_test.csv')
		path = get_test_data_file_path('../../../rawdata/PublicParcelExtract.csv')
		skip("#{path} not found") unless File.exist?(path)

		File.open(path, 'r') do |file|
			size = File.size(file)
			count = 0
			time = Benchmark.measure do 
				file.each do |line|
					count += 1
				end
			end

			puts "Ruby native file IO: Read #{size / MB} MB/#{count} lines in #{time.real}.  #{size / MB / time.real} MB/sec  #{count / time.real} lines/sec"
		end
	end

	test "how fast can we write to /dev/null" do
		time = Benchmark.measure do 
			File.open('/dev/null', 'w') do |write|
				write.binmode
			
				count = 0
				LINES.times do 
					write.write LINE
					count += 1
				end
			end
		end

		puts "write to /dev/null: Wrote #{SIZE / MB} MB/#{LINES} lines in #{time.real}.  #{SIZE / MB / time.real} MB/sec  #{LINES / time.real} lines/sec"
	end

	test "how fast can we syswrite to /dev/null" do
		time = Benchmark.measure do 
			File.open('/dev/null', 'w') do |write|
				write.binmode
			
				count = 0
				LINES.times do 
					write.syswrite LINE
					count += 1
				end
			end
		end

		puts "syswrite to /dev/null: Wrote #{SIZE / MB} MB/#{LINES} lines in #{time.real}.  #{SIZE / MB / time.real} MB/sec  #{LINES / time.real} lines/sec"
	end

	test "are pipes within the same process slow" do
		read, write = IO.pipe

		time = Benchmark.measure do 
			count = 0
			LINES.times do 
				write.puts LINE
				assert_equal LINE, read.gets.rstrip
				count += 1
			end
			write.close

			assert read.eof?
			read.close
		end

		puts "Pipes in process: Read #{SIZE / MB} MB/#{LINES} lines in #{time.real}.  #{SIZE / MB / time.real} MB/sec  #{LINES / time.real} lines/sec"
	end

	test "are pipes to a child forked process slow" do
		read, write = IO.pipe

		time = Benchmark.measure do 
			child_id = fork {
				count = 0
				write.close

				read.each do |line|
					assert_equal LINE, line.rstrip

					count += 1

					if count % 1000 == 0 
						#puts "from child: #{count} rows processed"
					end
				end

				read.close

				assert_equal LINES, count
			}

			count = 0
			read.close
			LINES.times do 
				write.puts LINE
				count += 1
				if count % 1000 == 0 
					#puts "from parent: #{count} rows processed"
				end
			end
			write.close

			Process.waitall
		end

		puts "Pipes: Read #{SIZE / MB} MB/#{LINES} lines in #{time.real}.  #{SIZE / MB / time.real} MB/sec  #{LINES / time.real} lines/sec"
	end

	test "can we speed things up with binary transfers and syswrite" do
		read, write = IO.pipe
		read.binmode
		write.binmode

		time = Benchmark.measure do 
			child_id = fork {
				bytes = 0
				write.close
				buffer = String.new()

				while !read.eof? do
					data = read.readpartial(4096)
					bytes += data.length
				end

				read.close

				assert_equal SIZE, bytes
			}

			count = 0
			read.close
			LINES.times do 
				write.syswrite LINE
				count += 1
				if count % 1000 == 0 
					#puts "from parent: #{count} rows processed"
				end
			end
			write.close

			Process.waitall
		end

		puts "Binary pipes and syswrite: Read #{SIZE / MB} MB/#{LINES} lines in #{time.real}.  #{SIZE / MB / time.real} MB/sec  #{LINES / time.real} lines/sec"
	end

	test "can we speed things up with binary transfers and syswrite and sysread" do
		read, write = IO.pipe
		read.binmode
		read.sync = true
		write.binmode
		write.sync = true

		time = Benchmark.measure do 
			child_id = fork {
				bytes = 0
				write.close
				buffer = String.new()

				read_array = [read]

				while true do
					begin
						IO.select read_array
						data = read.sysread(4096, buffer)
						bytes += data.length
					rescue EOFError
						break
					end
				end

				read.close

				assert_equal SIZE, bytes
			}

			count = 0
			read.close
			LINES.times do 
				write.syswrite LINE
				count += 1
				if count % 1000 == 0 
					#puts "from parent: #{count} rows processed"
				end
			end
			write.close

			Process.waitall
		end

		puts "Binary pipes and syswrite and sysread: Read #{SIZE / MB} MB/#{LINES} lines in #{time.real}.  #{SIZE / MB / time.real} MB/sec  #{LINES / time.real} lines/sec"
	end

	test "can we speed things up more with big preallocated buffers" do
		read, write = IO.pipe
		read.binmode
		read.sync = true
		write.binmode
		write.sync = true

		time = Benchmark.measure do 
			buffer = '\0' * 65536
			child_id = fork {
				bytes = 0
				write.close

				read_array = [read]

				while true do
					begin
						IO.select read_array
						data = read.sysread(65536, buffer)
						bytes += data.length
					rescue EOFError
						break
					end
				end

				read.close

				assert_equal SIZE, bytes
			}

			count = 0
			read.close
			LINES.times do 
				write.syswrite LINE
				count += 1
				if count % 1000 == 0 
					#puts "from parent: #{count} rows processed"
				end
			end
			write.close

			Process.waitall
		end

		puts "Binary pipes and syswrite and sysread and 64k buff: Read #{SIZE / MB} MB/#{LINES} lines in #{time.real}.  #{SIZE / MB / time.real} MB/sec  #{LINES / time.real} lines/sec"
	end

	test "how fast can we go with msgpack" do
		read, write = IO.pipe
		read.binmode
		read.sync = true
		write.binmode
		write.sync = true

		time = Benchmark.measure do 
			buffer = '\0' * 65536
			child_id = fork {
				bytes = 0
				objects = 0
				write.close

				unpacker = MessagePack::Unpacker.new

				while true do
					begin
						data = read.sysread(65536, buffer)
						bytes += data.length

						unpacker.feed_each(data) do |obj|
							#puts "obj: #{obj}"
							assert_equal LINE, obj["line"]

							objects += 1
						end
					rescue EOFError
						break
					end
				end

				read.close

				assert_equal LINES, objects
			}

			count = 0
			read.close
			obj = { :line => nil }

			LINES.times do 
				obj[:line] = LINE

				write.syswrite obj.to_msgpack

				count += 1
				if count % 1000 == 0 
					#puts "from parent: #{count} rows processed"
				end
			end
			write.close

			assert_equal LINES, count

			Process.waitall
		end

		puts "With msgpack: Read #{SIZE / MB} MB/#{LINES} lines in #{time.real}.  #{SIZE / MB / time.real} MB/sec  #{LINES / time.real} lines/sec"
	end

	test "how fast can we go with our msgpack serializing wrappers" do
		read, write = IO.pipe

		time = Benchmark.measure do 
			child_id = fork {
				objects = 0
				write.close

				reader = Prima::MsgpackIoReader.new read
				reader.each do |obj|
					#puts "obj: #{obj}"
					assert_equal LINE, obj["line"]

					objects += 1
				end

				read.close

				assert_equal LINES, objects
			}

			count = 0
			read.close
			obj = { :line => nil }
			writer = Prima::MsgpackIoWriter.new write
			LINES.times do 
				obj[:line] = LINE

				writer.write obj

				count += 1
				if count % 1000 == 0 
					#puts "from parent: #{count} rows processed"
				end
			end
			write.close

			assert_equal LINES, count

			Process.waitall
		end

		puts "With msgpack IO adapters: Read #{LINES} lines in #{time.real}.  #{LINES / time.real} lines/sec"
	end

	test "how slow are our ETL classes" do
		read, write = IO.pipe


		time = Benchmark.measure do 
			child_id = fork {
				begin
					objects = 0
					write.close

					step = Prima::NullStep.new
					step.incoming = read

					step.run
				rescue Interrupt => e
					sleep 1
					puts "*************************************"
					puts "The child has been interrupted: "
					puts e.to_s
					puts "*************************************"

					raise e
				end
			}

			count = 0
			read.close
			obj = { :line => nil }
			writer = Prima::MsgpackIoWriter.new write
			LINES.times do 
				obj[:line] = LINE

				writer.write obj

				count += 1
				if count % 1000 == 0 
					#puts "from parent: #{count} rows processed"
				end
			end
			write.close

			assert_equal LINES, count

			Process.waitall
		end

		puts "With NullStep ETL class as reader: Read #{LINES} lines in #{time.real}.  #{LINES / time.real} lines/sec"
	end

	test "how fast is msgpack by itself" do
		time = Benchmark.measure do 
			obj = { :line => nil }
			LINES.times do 
				obj[:line] = LINE
				obj.to_msgpack
			end
		end

		puts "msgpack packer: #{SIZE / MB} MB/#{LINES} lines in #{time.real}.  #{SIZE / MB / time.real} MB/sec  #{LINES / time.real} lines/sec"

		time = Benchmark.measure do 
			unpacker = MessagePack::Unpacker.new
			obj = { :line => LINE }
			data = obj.to_msgpack

			LINES.times do 
				unpacker.feed_each(data) do |obj|
				end
			end
		end

		puts "msgpack unpacker: #{SIZE / MB} MB/#{LINES} lines in #{time.real}.  #{SIZE / MB / time.real} MB/sec  #{LINES / time.real} lines/sec"
	end
end
