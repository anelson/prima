module Prima
	# Maps input elements to output elements
	class MapperStep < TransformStep
		private_class_method :new

		def initialize(key = 'data')
			super()

			@key = key
			@mappings = {}
			@block = nil
		end

		def self.define_mappings(key: 'data', &block)
			me = new(key)

			block.call me

			me
		end

		def map(hash)
			@mappings = @mappings.merge(hash)
		end

		def map_ordinal(key, new_key) 
			@mappings[key] = new_key
		end

		def map_name(key, new_key)
			@mappings[key] = new_key
		end

		def map_ordinal_by_array(new_keys, start_ordinal: 0)
			new_keys.each_with_index do |key, ordinal|
				map_ordinal ordinal, key
			end
		end

		def map_custom(&block)
			@block = block
		end

		def process_row(row)
			input = row[@key]

			output = {}

			output.merge! @block.call input unless @block == nil

			@mappings.each do |k,v|
				if input.is_a?(Hash)
					# Make sure the input key exists
					raise "Input key '#{k}' does not exist" unless input.include?(k)
				elsif input.is_a?(Array)
					raise "Input ordinal '#{k}' is out of range" unless k >= 0 && k < input.length
				end

				output[v] = input[k]
			end

			row[@key] = output

			row
		end
	end
end