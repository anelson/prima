module Prima
	# A surprisingly handy step that does nothing; it produces no output regardless of the input
	class NullStep < SinkStep
		def each_input
			# As an optimization in the common case, in which the input of NullStep 
			# is an IO object, don't bother msgpack decoding the input; just ignore it all
			if @incoming.is_a?(MsgpackIoReader) && @incoming.io.respond_to?(:sysread)
				buffer = '\0' * MsgpackIoReader::BUFFER_SIZE

				eof = false
				while !eof
					begin
						@incoming.io.sysread(MsgpackIoReader::BUFFER_SIZE, buffer)
					rescue EOFError
						#End of the stream
						eof = true
					end
				end
			else
				Prima.logger.debug "#{@incoming} does not respond to sysread; performing slower msgpack read"
				super
			end
		end
		def process_row(row); nil; end

		def handle_output(row); nil; end
	end
end