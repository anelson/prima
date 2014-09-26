module Prima
	# A surprisingly handy step that does nothing; it produces no output regardless of the input
	class NullStep < SinkStep
		def process_row(row); nil; end

		def handle_output(row); nil; end
	end
end