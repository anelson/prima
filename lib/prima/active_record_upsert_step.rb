require 'active_record'
require 'upsert/active_record_upsert'

module Prima
	# A very useful sink step which maps the input row into an ActiveRecord model object and uses the upsert
	# gem to attempt a high performance upsert
	class ActiveRecordUpsertStep < SinkStep
		def initialize(model_class, selector = nil)
			super()

			@model_class = model_class
			@selector = selector || [ @model_class.primary_key ]
		end

		def process_row(row)
			upsert_row(row, row['data'])
		end

		def upsert_row(row, data)
			# Figure out which input attributes will be used
			included_keys = data.keys.select { |k| include_key?(k) }
			# Figure out the mapping of input keys to model attributes
			attribute_mapping = included_keys.each_with_object({}) do |key, h| 
				attribute = map_key_to_attribute(key)
				h[key] = attribute unless attribute == nil
			end

			# Attempt to cast each input value into the appropriate column type.  This is also where a subclass
			# can do whatever other processing it needs on a specific column
			typed_values = attribute_mapping.each_with_object({}) do |(key, attribute), h| 
				h[attribute] = type_cast(key, attribute, data[key])
			end

			selector = typed_values.select { |k,v| @selector.include?(k) }
			setter = typed_values.select { |k,v| !@selector.include?(k) }

			@model_class.upsert selector, setter
		end

		# Can be overridden in subclasses to exclude some input data values so they are not processed further
		def include_key?(key)
			true
		end

		# Determines which attribute on the model is used to populate 
		def map_key_to_attribute(key)
			# By default, convert the key to snake case and find a matching attribute
			name = key.underscore

			@model_class.column_names.include?(name) ? name : nil
		end

		def type_cast(input_key, model_attribute, input_value)
			@model_class.columns_hash[model_attribute].type_cast input_value
		end
	end
end
