require 'rodimus'
require 'msgpack'

# Base class for all of our ETL steps.  Adds several nice capabilities on top of Rodimus, like
# serializing objects between steps instead of using strings
class EtlStep < Rodimus::Step
	# Must be set to the transformation this step is running in or shared data will fail
	attr_accessor :transformation

	def initialize
		super()

		# Steps run in a forked process, and once the step finishes the process dies, so any state
		# maintained by that step won't be visible to the parent process unless it's stored in the shared data
		# hash.  To avoid collissions between steps, we need a unique key for just this step
		@shared_data_key = self.class.name + "::" + self.hash.to_s

		# It's VERY easy to forget to call the base class ctor, and when you do the step won't work at all
		# To avoid head scratching and throwing things, catch this common mistake and make it explicit
		@ctor_called = true

		@discovered_hooks_cache = {}
	end

	def notify(subject, event)
		if @ctor_called != true
			raise "There is a problem with #{self.class.name}!  It does not call the base class constructor so this step is not set up properly"
		end

		super
	end

	# Rodimus uses an observer pattern to allow other code to hook in to various places.  This is useful but the
	# implementation really REALLY sucks performance wise.  This re-implementation caches the hooks for each event
	# type so it doesn't have to go on a reflection expedition every time
	def on_notify(subject, event_type)
		hooks = @discovered_hooks_cache[event_type]
		if hooks == nil
			hooks = discovered_hooks(event_type)
			@discovered_hooks_cache[event_type] = hooks
		end

		hooks.each do |hook|
			self.send hook
		end
	end

	def method_missing(meth, *args, &block)
		# Dynamically implement shared_X and shared_X= accessors as readers and writers of shared data
		if meth.to_s =~ /^shared_(.+)\=$/
			write_shared_data($1, args[0])
		elsif meth.to_s =~ /^shared_(.+)$/
			read_shared_data($1)
		else
			puts "Method #{meth} is missing"
			super
		end
	end

	def respond_to?(meth)
		if meth.to_s =~ /^shared_(.+)\=$/
			true
		elsif meth.to_s =~ /^shared_(.+)$/
			true
		else
			super
		end
	end

	protected

	# Gets a transform-unique key given a key specific to this step
	def shared_data_key_name(key)
		@shared_data_key + "::" + key
	end

	# If this step is running, meaning it's in a forked child process, its @shared_data member
	# will have been set by Transformation.run to a DRb client version that passes calls back to the server in the parent process
	#
	# If however this is called from the parent process before the step runs or after it finishes, @shared_data
	# is null, therefore the @shared_data collection on the transformation should be used
	def shared_data_hash
		@shared_data || @transformation.shared_data
	end

	def read_shared_data(key)
		#puts "read_shared_data: key=#{key} hash=#{shared_data_hash}"
		shared_data_hash[shared_data_key_name(key)]
	end

	def write_shared_data(key, value)
		shared_data_hash[shared_data_key_name(key)] = value
		#puts "write_shared_data: key=#{key} value=#{value} hash=#{shared_data_hash}"
	end
end
