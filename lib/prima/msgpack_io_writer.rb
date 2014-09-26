require 'msgpack'

module Prima
	# Adapter around an IO object so any attempt to write to it is serialized with msgpack and passed to the
	# underlying IO very fast
	class MsgpackIoWriter
		def initialize(io)
			@io = io

			@io.binmode
			@io.sync = true # disable Ruby buffering
		end

		def close
			if @io != nil
				@io.close
				@io = nil
			end
		end

		def write(obj)
			@io.syswrite obj.to_msgpack
		end
	end
end