require 'msgpack'

module Prima
	# Wraps an IO object just enoguh to fool Rodimus into treating it as an incoming stream, 
	# while doing high performance direct OS calls under the covers and serializing input from msgpack
	class MsgpackIoReader
		BUFFER_SIZE = 65536

		def initialize(io)
			@io = io
			@unpacker = MessagePack::Unpacker.new

			@io.binmode
			@io.sync = true # disable Ruby buffering
		end

		def close
			if @io != nil
				@io.close
				@io = nil
			end
		end

		def each
			# Read the stream until the end, yielding each object we get along the way
			buffer = '\0' * BUFFER_SIZE

			eof = false
			while !eof
				begin
					data = @io.sysread(BUFFER_SIZE, buffer)
					@unpacker.feed_each(data) do |obj|
						yield obj
					end
				rescue EOFError
					#End of the stream
					eof = true
				end
			end
		end
	end
end