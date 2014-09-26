require 'rodimus'
require 'ruby-progressbar'

module Prima
	class ProgressReporter
		include Rodimus::Observing

		def self.attach(step)
			me = ProgressReporter.new(step)

			step.observers << me

			me
		end

		def initialize(step)
			@step = step
			@count = 0
		end

		def before_run
			@progressbar = ProgressBar.create(:title => @step.class, :total => nil, :format => "%t: Records: %c Elapsed %a Records/second: %r  %b")
		end

		def after_row
			@progressbar.increment
			@count += 1
		end

		def after_run
			@progressbar.total = @count
			@progressbar.finish
		end
	end
end