require 'set'
require 'thread_safe'

module Prima
	#Dirt simple pub/sub framework inspired by Observable/Observer in nevern02's rodimus gem
  module Publisher
    def publish(event, *args)
    	return unless @subscribers != nil && @subscribers.length > 0

    	# The process of sending out notifications isn't without cost, and it can add up
    	# if one of the events is very common, like our per-row events.  Thus, try to find otu
    	# when events are being ignored and don't send them anymore
    	@handled_events_cache ||= ThreadSafe::Cache.new
    	#@handled_events_cache ||= Hash.new(nil)

    	#handled = @handled_events_cache[event]
    	handled = @handled_events_cache.fetch(event, nil)

    	if handled == false
    		# Most common case; do nothing
    	elsif handled == true
	      subscribers.each do |subscriber|
	        subscriber.on_notify(event, args)
	      end
	    else
	    	#This means it's the first time this event is raised.  Send to all subscribers and see if any of them handle it
	    	handled = false

	      @subscribers.each do |subscriber|
					handled = true if subscriber.on_notify(event, args)
	      end

	      @handled_events_cache[event] = handled
	    end
    end

    def subscribe(subscriber)
      subscribers << subscriber
    end

    def subscribers
    	@subscribers ||= Array.new
    end
  end
end