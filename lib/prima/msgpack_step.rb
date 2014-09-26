# Don't include this module directly.  Use msgpackinput and/or msgpackoutput

module Prima
	module MsgpackStep
		def close_descriptors
			#Call the base class to close either incoming or outgoing descriptors of the more
			#conventional kind (like IO).  For some reason the Packer/Unpacker do not have a close
			#method to close the underlying stream.  So we must do it ourselves
			super()

			[incoming, outgoing].reject(&:nil?).each do |descriptor|
	        descriptor.buffer.io.close if descriptor.respond_to?(:buffer) && descriptor.buffer.io.respond_to?(:close) && !descriptor.buffer.io.closed?
	    end
		end
	end
end