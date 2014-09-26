require 'csv'

module Prima
	# transform which takes input where the 'data' element contains a CSV-formatted row of data, and outputs
	# with the 'data' element rewritten into a hash with one entry for each column.
	#
	# column names can be derived from a header, if present, or they can be ordinal numbers starting from 0
	class CsvParserStep < TransformStep
		# The Ruby CSV parser is used here, so the options hash can contain any options supported by the CSV parser itself
		def initialize(header_row: false, options: Hash.new)
			super()
			
			@header_row = header_row
			@options = CSV::DEFAULT_OPTIONS.merge(Hash[:converters => [:blank_to_nil]]).merge(options)

			CSV::Converters[:blank_to_nil] = lambda do |field|
			  field && field.empty? ? nil : field
			end
				
			@column_names = []
		end

		def before_run(step)
			if @header_row 
				@column_names = []
			end
		end

		def process_row(row)
			data = row['data']

			if @header_row && @column_names.empty?
				#This is the first row; read it as a column header
				@column_names = try_parse_csv(data)

				#Do not pass this on to the output stream
				nil
			else
				if @header_row
					#produce a hash table with the column names
					row['data'] = Hash[@column_names.zip(try_parse_csv(data))]
				else
					row['data'] = try_parse_csv(data)
				end

				#Output this modified row, maintaining whatever metadata elements were already there
				row
			end
		end

		def try_parse_csv(row)
			# Try to parse with Ruby's CSV library, but sometimes we'll get a row like this:
			#   "0142060661970","01","ANDREA DE GAETANO","","","ANDREA DE GAETANO","","LAGO DELL"OLGLATA 15","ISOLA 69H1 00123 ROME","","","ITALY","325 S BISCAYNE BLVD 1419","325","S","BISCAYNE","","BLVD","","1419","Miami","33131-2306","0407","6401","1227.00","0.00","0.0000","2","2.00","0","1","0","1","2005","2005","0101","2014","0","0","0","364890","0","0","0","0","0","0","0","0","0","0","271330","0","271330","0","271330","0","271330","0","364890","2013","0","0","0","269090","0","0","0","0","0","0","0","0","0","0","246664","0","246664","0","246664","0","246664","0","269090","2012","0","0","0","224240","0","0","0","0","0","0","0","0","0","0","224240","0","224240","0","224240","0","224240","0","224240"
			#
			# where one of the columns contains a quote.  In this case we fall back to a parsing logic based on Ruby split
			begin
				CSV.parse(row, @options)[0]
			rescue CSV::MalformedCSVError => e
				# Chop leading and trailing quotes, then split the rest
				fixedrow = row.strip()[1..-2].split(@options[:quote_char] + @options[:col_sep] + @options[:quote_char])

				Rails.logger.info "Fixed malformed row [[#{row}]] as [[#{fixedrow}]]"

				fixedrow
			end
		end
	end
end

