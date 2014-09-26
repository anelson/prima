module Prima
	# A special filter that filters input on a regular expression
	class RegexFilterStep < TransformStep
		def initialize(regex, key: 'data')
			super()
			@regex = Regexp.compile(regex)
			@key = key
		end

		def process_row(row)
			match = @regex.match(row[@key])

			if match != nil
				#If there are any named match groups, add them to the data in the row
				if (match.names.any?)
					row[@key] = Hash[match.names.zip(match.captures)]
				elsif match.captures.any?
					row[@key] = match.captures.first
				else
					row[@key] = match.to_s
				end

				row
			else
				nil
			end
		end
	end
end