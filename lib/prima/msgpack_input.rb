#Mixin to include in an ETL step when its incoming stream is expected to contain msgpack-serialized objects

module Prima
	module MsgpackInput
		include MsgpackStep
		
		# Called by Rodimus Transformation (and hopefully nowhere else) to attach the input of a step
		# to the pipe connected to the output of another step.  Assume it's an IO object that operates in 
		# terms of strings.  Wrap it with a MessagePack packer so we can write objects to it, and 
		# have them serialized properly
		#
		# NB: If you are writing a step that sources external data, make sure you set '@incoming' directly,
		# and don't go through this accessor, or you're gonna have a bad time.  Then again, if your step is sourcing
		# input from external data, you shouldn't be using this mixin
		def incoming=(pipe)
			@incoming = MsgpackIoReader.new(pipe)
		end
	end
end