module Prima
	# An interesting step.  Takes as input an array of steps.  When this step runs, it passes each row through
	# all of the steps in the array, in order, with the final step's output being the output of this step
	#
	# Why is this useful?  Rodimus runs each step in its own process, so we have overhead serializing and deeserializing 
	# each row through msgpack.  msgpack is fast, but it can't work miracles.  All steps inside this container step
	# run sequentially, in a single thread in a single process, so there is practically no overhead.  Use this 
	# to combine multiple simple steps like filters or parsers for whcih there is no computational benefit so spinning
	# up another process for each one.
	class ContainerStep < TransformStep
		attr_reader :steps
		def initialize(steps)
			super()

			@steps = steps
		end

		def on_notify(subject, event)
			super

			@steps.each do |step|
				step.on_notify(subject, event)
			end
		end

		def process_row(row)
			@steps.each do |step|
				row = step.process_row(row)
				break if row == nil
			end

			row
		end
	end
end