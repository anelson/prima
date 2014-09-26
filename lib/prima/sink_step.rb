module Prima
	# Base class for steps that take input from another step, and output it to some external system like a database or a file
	class SinkStep < EtlStep
		include MsgpackInput

		# Sink steps have no output in our sense of the word; they output to some other system but not a subsqeuent step
		def handle_output(row); nil; end
	end
end