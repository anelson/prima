require 'drb'

require 'thread_safe'

module Prima
	# A transformation, which hosts multiple steps
	#
	# Based on the Transformation class in Rodimus
	class Transformation
    include Publisher
    include Subscriber # Transformations subscribe to themselves for run hooks

		class UndumpedSharedDataHash < ThreadSafe::Cache
			# Ensure Drb doesn't try to marshall this by value between processes.  I don't knwo for sure that it will
			# but i want to be extra careful
			include DRb::DRbUndumped
		end

    attr_reader :drb_server, :steps

    # Contains the thread or process identifiers currently in use
    attr_reader :ids

    # User-data accessible across all running steps.
    attr_reader :shared_data

		def initialize()
			super()

			@shared_data = UndumpedSharedDataHash.new
      @steps = []
      @ids = []
      subscribe self
		end

		def add_step(step)
			step.transformation = self
			@steps << step
		end

		def before_run_aaa_close_connections(_)
			# Make sure all activerecord connections are closed before we fork the child processes.  Otherwise the children will close them on shutdown
			# and we will still think they are open
			if defined?(ActiveRecord)
				begin
					ActiveRecord::Base.connection_pool.disconnect!
				rescue ActiveRecord::ConnectionNotEstablished
					# It's fine if the connection isn't established
				end
			end
		end

    # Run the transformation
    def run
      @drb_server = DRb.start_service(nil, shared_data) unless using_threads?
      publish(:before_run, self)
      ids.clear
      prepare

      steps.each do |step|
        ids << in_parallel do
          step.shared_data = step_shared_data
          step.run
        end
        step.close_descriptors unless using_threads?
      end
    ensure
      cleanup
      publish(:after_run, self)
    end

    def to_s
      "#{self.class} with #{steps.length} steps"
    end

    private

    def cleanup
      if using_threads?
        ids.each { |t| t.join }
      else
        Process.waitall
        drb_server.stop_service
      end
    end
    
    def in_parallel 
      if using_threads?
        Thread.start { yield }
      else
        fork { yield }
      end
    end

    def prepare
      # [1, 2, 3, 4] => [1, 2], [2, 3], [3, 4]
      steps.inject do |first, second|
        read, write = IO.pipe
        first.outgoing = write
        second.incoming = read
        second
      end
    end

    def step_shared_data
      if using_threads?
        shared_data
      else
        DRb.start_service # service dies across forked process
        DRbObject.new_with_uri(drb_server.uri)
      end
    end

    def using_threads?
      Prima.configuration.use_threads
    end
  end
end