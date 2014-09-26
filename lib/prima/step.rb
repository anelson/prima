module Prima
	# Base class for all steps.  Derived heavily from Rodimus class of the same name
	class Step
		include Publisher
    include Subscriber # Steps observe themselves for run hooks

    # The incoming data stream.  Can be anything that quacks like an IO
    attr_accessor :incoming

    # The outgoing data stream.  Can be anything that quacks like an IO
    attr_accessor :outgoing

    # Shared user-data accessible across all running transformation steps.
    # This is initialized by the Transformation when the step begins to run.
    attr_accessor :shared_data

    def initialize
      subscribe self
      subscribe Benchmark.new if Prima.configuration.benchmarking
    end

    def close_descriptors
      [incoming, outgoing].reject(&:nil?).each do |descriptor|
        descriptor.close if descriptor.respond_to?(:close)
      end
    end

    # Override this for custom output handling functionality per-row.
    def handle_output(transformed_row)
      outgoing.puts(transformed_row)
    end

    # Override this for custom transformation functionality
    def process_row(row)
      row.to_s
    end

    def run
      publish(:before_run, self)
      @row_count = 1
      each_input do |row|
        publish(:before_row, self, row)
        transformed_row = process_row(row)
        handle_output(transformed_row)
        Prima.logger.info(self) { "#{@row_count} rows processed" } if @row_count % 50000 == 0
        @row_count += 1
        publish(:after_row, self, transformed_row)
      end
      publish(:after_run, self)
    ensure
      close_descriptors
    end

    def to_s
      "#{self.class} connected to input: #{incoming || 'nil'} and output: #{outgoing || 'nil'}"
    end

    protected

    # Override for steps that get input from something other than the @incoming stream
    def each_input
    	incoming.each do |row|
    		yield row
    	end
    end
	end
end