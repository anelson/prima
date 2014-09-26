require 'set'

module Prima
	#Dirt simple pub/sub framework inspired by Observable/Observer in nevern02's rodimus gem
  module Publisher
    def publish(event, *args)
      subscribers.each do |subscriber|
        subscriber.on_notify(event, args)
      end
    end

    def subscribe(subscriber)
      subscribers << subscriber
    end

    def subscribers
    	@subscribers ||= Set.new
    end
  end
end