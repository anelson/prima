# Shamelessly stolen from the gem that inspired Prima, Rodimus
require 'logger'

module Prima
  class Configuration
    attr_accessor :logger

    # Set to true for extra output with step performance details
    attr_accessor :benchmarking

    # Use threads for concurrency instead of forking processes.
    # Automatically set to true for JRuby and Rubinius
    attr_accessor :use_threads

    attr_accessor :progname

    def initialize
      @logger = Logger.new(STDOUT)
      @progname = 'prima'
      @benchmarking = false
      @use_threads = ['jruby', 'rbx'].include?(RUBY_ENGINE)
    end
  end

end