module Prima
  module Subscriber
  	# returns true if the subscriber handled this event type
  	# false if it was ignored.
  	# once false it returned once, the publisher may assume it doesn't need to notify
  	# this subscriber anymore for that particular event type.
    def on_notify(event_type, args)
    	# The process of discovering hooks is very expensive in that it uses grep on the method table.
    	# Some of our hooks are per row, so they can be invoked millions of times
    	# Every cycle counts boys and girls.
    	@discovered_hooks_cache ||= ThreadSafe::Cache.new

			hooks = @discovered_hooks_cache.fetch_or_store(event_type) do 
				discovere_hooks(event_type)
			end

			hooks.each do |hook|
				self.send hook, *args
			end

			hooks.any?
    end

    private

    def discovere_hooks(matcher)
      methods.grep(/^#{matcher}/)
    end
  end
end