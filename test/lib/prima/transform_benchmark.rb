require 'test_helper'

class TransformBenchmark < EtlTestCase
	PARCEL_FILE = "parcel_test.csv"
	PARCEL_FILE_ROWS = 20000
	PARCEL_FILE_DATA_ROWS = 19994

	#self.use_transactional_fixtures = true

	class RowCounterStep < SinkStep
		def before_run
			self.shared_count = 0
		end

		def process_row(row)
			self.shared_count += 1
			nil
		end

		def count
			self.shared_count
		end
	end

	def get_test_data_file_path(filename)
		File.dirname(__FILE__) + '/testdata/' + filename
	end

	def setup
		Rodimus.configure do |config|
			config.logger = Rails.logger
			config.benchmarking = true
		end
	end

	test "measure transform performance" do
		skip("too slow")
		Benchmark.benchmark("transform performance: ", 15, Benchmark::FORMAT) do |b|
			times = []

			times << run_transform(b, 'load all new: ') {
				Parcel.delete_all

				assert_equal 0, Parcel.count(:all)

				t = Transformation.new

				input = input_step
				t.add_step input

				# Strip leading and trailing " character as the prelude to parsing out the CSV
				filter = filter_step
				t.add_step filter

				csv = csv_step
				t.add_step csv

				mapper = mapper_step
				t.add_step mapper

				upsert = upsert_step
				t.add_step upsert
				
			 	t.run

				assert_equal PARCEL_FILE_DATA_ROWS, Parcel.count(:all)
			}

			times << run_transform(b, 'just reading: ') {
				t = Transformation.new

				input = input_step
				t.add_step input

				counter = counter_step
				t.add_step counter
				
				t.run

				assert_equal PARCEL_FILE_ROWS, counter.count
			} 

			times << run_transform(b, 'read and parse: ') {
				t = Transformation.new

				input = input_step
				t.add_step input

				# Strip leading and trailing " character as the prelude to parsing out the CSV
				filter = filter_step
				t.add_step filter

				csv = csv_step
				t.add_step csv

				counter = counter_step
				t.add_step counter
				
				t.run

				assert_equal PARCEL_FILE_DATA_ROWS, counter.count
			}

			times << run_transform(b, 'read and map: ') {
				t = Transformation.new

				input = input_step
				t.add_step input

				# Strip leading and trailing " character as the prelude to parsing out the CSV
				filter = filter_step
				t.add_step filter

				csv = csv_step
				t.add_step csv

				mapper = mapper_step
				t.add_step mapper

				counter = counter_step
				t.add_step counter
				
				t.run

				assert_equal PARCEL_FILE_DATA_ROWS, counter.count
			}

			times
		end
	end

	def run_transform(benchmark, label) 
		time = benchmark.report(label) {
			yield
		}

		puts "#{label}: #{PARCEL_FILE_ROWS / time.real} rows/second"

		time
	end

	def input_step
		TextFileInputStep.new(get_test_data_file_path(PARCEL_FILE))
	end

	def filter_step
		# Strip leading and trailing " character as the prelude to parsing out the CSV
		filter = RegexFilterStep.new(/^\"(.+)\"$/)	
	end

	def csv_step
		csv = CsvParserStep.new(header_row: false, options: { :quote_char => "\x00", :col_sep => "\",\"" })
	end

	def mapper_step
		MapperStep.define_mappings do |m|
			m.map_ordinal_by_array [
				'folio',
				'municipality',
				'owner1',
				'owner2',
				'owner3',
				'mailing_address_line1',
				'mailing_address_line2',
				'mailing_address_line3',
				'city',
				'state',
				'zip',
				'country',
				'site_address',
				'street_number',
				'street_prefix',
				'street_name',
				'street_number_suffix',
				'street_suffix',
				'street_direction',
				'condo_unit',
				'site_city',
				'site_zip',
				'd_o_r_code',
				'zoning',
				'sq_ftg',
				'lot_s_f',
				'acres',
				'bedrooms',
				'baths',
				'half_baths',
				'living_units',
				'stories',
				'number_of_building',
				'year_built',
				'effective_year_built',
				'millage_code',
				'current_year',
				'current_land_value',
				'current_building_value',
				'current_extra_feature_value',
				'current_total_value',
				'current_homestead_ex_value',
				'current_county_second_homestead_ex_value',
				'current_city_second_homestead_ex_value',
				'current_window_ex_value',
				'current_county_other_ex_value',
				'current_city_other_ex_value',
				'current_disability_ex_value',
				'current_county_senior_ex_value',
				'current_city_senior_ex_value',
				'current_blind_ex_value',
				'current_assessed_value',
				'current_county_exemption_value',
				'current_county_taxable_value',
				'current_city_exemption_value',
				'current_city_taxable_value',
				'current_regional_exemption_value',
				'current_regional_taxable_value',
				'current_school_exemption_value',
				'current_school_taxable_value',
				'prior_year',
				'prior_land_value',
				'prior_building_value',
				'prior_extra_feature_value',
				'prior_total_value',
				'prior_homestead_ex_value',
				'prior_county_second_homestead_ex_value',
				'prior_city_second_homestead_ex_value',
				'prior_window_ex_value',
				'prior_county_other_ex_value',
				'prior_city_other_ex_value',
				'prior_disability_ex_value',
				'prior_county_senior_ex_value',
				'prior_city_senior_ex_value',
				'prior_blind_ex_value',
				'prior_assessed_value',
				'prior_county_exemption_value',
				'prior_county_taxable_value',
				'prior_city_exemption_value',
				'prior_city_taxable_value',
				'prior_regional_exemption_value',
				'prior_regional_taxable_value',
				'prior_school_exemption_value',
				'prior_school_taxable_value',
				'prior2_year',
				'prior2_land_value',
				'prior2_building_value',
				'prior2_extra_feature_value',
				'prior2_total_value',
				'prior2_homestead_ex_value',
				'prior2_county_second_homestead_ex_value',
				'prior2_city_second_homestead_ex_value',
				'prior2_window_ex_value',
				'prior2_county_other_ex_value',
				'prior2_city_other_ex_value',
				'prior2_disability_ex_value',
				'prior2_county_senior_ex_value',
				'prior2_city_senior_ex_value',
				'prior2_blind_ex_value',
				'prior2_assessed_value',
				'prior2_county_exemption_value',
				'prior2_county_taxable_value',
				'prior2_city_exemption_value',
				'prior2_city_taxable_value',
				'prior2_regional_exemption_value',
				'prior2_regional_taxable_value',
				'prior2_school_exemption_value',
				'prior2_school_taxable_value'
			]
		end
	end

	def upsert_step
		ActiveRecordUpsertStep.new(Parcel, [ 'folio' ] )
	end

	def counter_step
		RowCounterStep.new
	end
end
