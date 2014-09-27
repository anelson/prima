require 'stackprof'

module Prima
	# Subscriber to step events that uses stackprof to profile the step's execution
	class StepProfiler
		include Subscriber
		
		def initialize(dump_file_prefix, mode: mode = :cpu, interval: interval = 1000)
			@dump_file_prefix = dump_file_prefix
			@mode = mode
			@interval = interval
		end

		def before_run_start_profiler(step)
			# Each step runs in its own process, forked from the parent, so even though it seems wrong,
			# we can safely act like this is the only step we're processing
			@filename = @dump_file_prefix + '_' + step.class.name + '.dump'
			StackProf.start(mode: @mode, interval: @interval)
		end

		def after_run_stop_profiler(step)
			StackProf.stop

			StackProf.results @filename

			puts "Wrote stackprof dump to #{@filename}"
		end
	end
end