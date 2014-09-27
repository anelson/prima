require 'prima/version'
require 'prima/configuration'

require 'prima/publisher'
require 'prima/subscriber'

require 'prima/benchmark'

require 'prima/transformation'

require 'prima/step'
require 'prima/etl_step'
require 'prima/missing_msgpack_types'
require 'prima/msgpack_step'
require 'prima/msgpack_input'
require 'prima/msgpack_io_reader'
require 'prima/msgpack_io_writer'
require 'prima/msgpack_output'
require 'prima/sink_step'
require 'prima/source_step'
require 'prima/transform_step'
require 'prima/active_record_upsert_step'
require 'prima/container_step'
require 'prima/csv_parser_step'
require 'prima/filter_step'
require 'prima/mapper_step'
require 'prima/null_step'
require 'prima/regex_filter_step'
require 'prima/text_file_input_step'

require 'prima/progress_reporter'
require 'prima/step_profiler'

module Prima
  class << self
    attr_accessor :configuration
  end
  self.configuration = Configuration.new

  def self.configure
    yield configuration
  end

  def self.logger
    configuration.logger
  end

  unless Prima.configuration.use_threads
    $SAFE = 1 # Because we're using DRb
  end
end