module Prima
	# Base class for steps that take input from some other step, perform some sort of transformation on it, and send the output
	# to a subsequent step
	class TransformStep < EtlStep
		include MsgpackInput
		include MsgpackOutput
	end
end
