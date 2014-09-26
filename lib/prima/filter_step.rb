module Prima
	# A kind of transform step that passes each input directly to the output, but only if a user-defined
	# function evaluates to true when called for the input
	class FilterStep < TransformStep
		def initialize(filter_proc)
			super()
			@filter_proc = filter_proc
		end

		def process_row(row)
			if @filter_proc.call row
				row
			else
				nil
			end
		end
	end
end