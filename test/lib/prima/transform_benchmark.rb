require 'test_helper'
require 'benchmark'

class TransformBenchmark < EtlTestCase
	PARCEL_FILE = "parcel_test.csv"
	PARCEL_FILE_ROWS = 20000
	PARCEL_FILE_DATA_ROWS = 19994

	BIG_FILE_NAME = 'tmp/bigfile.csv'
	BIG_FILE_HEADER = <<EOF
H Miami-Dade County  Property Appraiser   -   Parcel Extract File   -   Roll year: 2014. Data is as of 09/14/2014
The Office of the Property Appraiser and Miami-Dade County are continually editing and updating the tax roll and GIS data to reflect the latest property information and GIS positional accuracy. No warranties - expressed or implied - are provided for data and the positional or thematic accuracy of the data herein - its use - or its interpretation. Although this website is periodically updated - this information may not reflect the data currently on file at Miami-Dade County’s systems of record.
The Property Appraiser and Miami-Dade County assumes no liability either for any errors - omissions - or inaccuracies in the information provided regardless of the cause of such or for any decision made - action taken - or action not taken by the user in reliance upon any information provided herein. See Miami-Dade County full disclaimer and User Agreement at http://www.miamidade.gov/info/disclaimer.asp

Folio,Municipality,Owner1,Owner2,Owner3,MailingAddressLine1,MailingAddressLine2,MailingAddressLine3,City,State,Zip,Country,SiteAddress,StreetNumber,StreetPrefix,StreetName,StreetNumberSuffix,StreetSuffix,StreetDirection,CondoUnit,SiteCity,SiteZip,DORCode,Zoning,SqFtg,LotSF,Acres,Bedrooms,Baths,1/2 Baths,LivingUnits,Stories,NumberOfBuilding,YearBuilt,EffectiveYearBuilt,MillageCode,CurrentYear,CurrentLandValue,CurrentBuildingValue,CurrentExtraFeatureValue,CurrentTotalValue,CurrentHomesteadExValue,CurrentCountySecondHomesteadExValue,CurrentCitySecondHomesteadExValue,CurrentWindowExValue,CurrentCountyOtherExValue,CurrentCityOtherExValue,CurrentDisabilityExValue,CurrentCountySeniorExValue,CurrentCitySeniorExValue,CurrentBlindExValue,CurrentAssessedValue,CurrentCountyExemptionValue,CurrentCountyTaxableValue,CurrentCityExemptionValue,CurrentCityTaxableValue,CurrentRegionalExemptionValue,CurrentRegionalTaxableValue,CurrentSchoolExemptionValue,CurrentSchoolTaxableValue,PriorYear,PriorLandValue,PriorBuildingValue,PriorExtraFeatureValue,PriorTotalValue,PriorHomesteadExValue,PriorCountySecondHomesteadExValue,PriorCitySecondHomesteadExValue,PriorWindowExValue,PriorCountyOtherExValue,PriorCityOtherExValue,PriorDisabilityExValue,PriorCountySeniorExValue,PriorCitySeniorExValue,PriorBlindExValue,PriorAssessedValue,PriorCountyExemptionValue,PriorCountyTaxableValue,PriorCityExemptionValue,PriorCityTaxableValue,PriorRegionalExemptionValue,PriorRegionalTaxableValue,PriorSchoolExemptionValue,PriorSchoolTaxableValue,Prior2Year,Prior2LandValue,Prior2BuildingValue,Prior2ExtraFeatureValue,Prior2TotalValue,Prior2HomesteadExValue,Prior2CountySecondHomesteadExValue,Prior2CitySecondHomesteadExValue,Prior2WindowExValue,Prior2CountyOtherExValue,Prior2CityOtherExValue,Prior2DisabilityExValue,Prior2CountySeniorExValue,Prior2CitySeniorExValue,Prior2BlindExValue,Prior2AssessedValue,Prior2CountyExemptionValue,Prior2CountyTaxableValue,Prior2CityExemptionValue,Prior2CityTaxableValue,Prior2RegionalExemptionValue,Prior2RegionalTaxableValue,Prior2SchoolExemptionValue,Prior2SchoolTaxableValue
EOF
	BIG_FILE_LINE = %q{"0131260380481","01","MARIA GUERRERO","CARIDAD GARCIA","","MARIA GUERRERO","CARIDAD GARCIA","1430 NW 35 ST","MIAMI","FL","33142-5550","","1430 NW 35 ST","1430","NW","35","","ST","","","Miami","33142-5550","0802","5700","2182.00","5440.00","0.1249","4","2.00","0","2","1","1","2001","2001","0100","2014","13125","129611","416","143152","0","0","0","0","0","0","0","0","0","0","92750","0","92750","0","92750","0","92750","0","143152","2013","11074","72824","421","84319","0","0","0","0","0","0","0","0","0","0","84319","0","84319","0","84319","0","84319","0","84319","2012","11505","69530","461","81496","0","0","0","0","0","0","0","0","0","0","81496","0","81496","0","81496","0","81496","0","81496"}
	BIG_FILE_LINES = 800000
	BIG_FILE_FOOTER = %q{F Miami-Dade County  Property Appraiser   -   Parcel Extract File   -   Data is as of 09/14/2014   -   File contains 000892017 Records}


	#self.use_transactional_fixtures = true

	class RowCounterStep < Prima::SinkStep
		def before_run(step)
			self.shared_count = 0
			@count = 0
		end

		def process_row(row)
			# This will kill performance so don't write it to shared storage right away
			@count += 1
			nil
		end

		def after_run(step)
			self.shared_count = @count
		end

		def count
			self.shared_count
		end
	end

	def get_test_data_file_path(filename)
		File.dirname(__FILE__) + '/testdata/' + filename
	end

	def test_real_transfer_except_no_database
		profiler = Prima::StepProfiler.new 'tmp/transform'

		if !File.exist?(BIG_FILE_NAME)
			puts "Creating big file #{BIG_FILE_NAME}"
			File.open(BIG_FILE_NAME, 'w') do |file|
				file.write BIG_FILE_HEADER
				TransformBenchmark::BIG_FILE_LINES.times { file.puts BIG_FILE_LINE }
				file.puts BIG_FILE_FOOTER
			end
		end
		
		times = Benchmark.measure do
			t = Prima::Transformation.new

			input = input_step(file: BIG_FILE_NAME)
			input.subscribe(profiler) if profiler != nil
			t.add_step input

			# Strip leading and trailing " character as the prelude to parsing out the CSV
			filter = filter_step
			filter.subscribe(profiler) if profiler != nil
			t.add_step filter

			csv = csv_step
			csv.subscribe(profiler) if profiler != nil
			t.add_step csv

			mapper = mapper_step
			mapper.subscribe(profiler) if profiler != nil
			t.add_step mapper

			counter = counter_step
			counter.subscribe(profiler) if profiler != nil
			t.add_step counter
			
		 	t.run

		 	assert_equal BIG_FILE_LINES, counter.count
		end

		puts "#{BIG_FILE_LINES} lines processed in #{times.real} seconds; #{BIG_FILE_LINES / times.real} lines/sec"
	end

	test "measure transform performance" do
		skip("not ready")
		::Benchmark.benchmark("transform performance: ", 15, Benchmark::FORMAT) do |b|
			times = []

			times << run_transform(b, 'load all new: ') {
				Parcel.delete_all

				assert_equal 0, Parcel.count(:all)

				t = Prima::Transformation.new

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
				t = Prima::Transformation.new

				input = input_step
				t.add_step input

				counter = counter_step
				t.add_step counter
				
				t.run

				assert_equal PARCEL_FILE_ROWS, counter.count
			} 

			times << run_transform(b, 'read and parse: ') {
				t = Prima::Transformation.new

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
				t = Prima::Transformation.new

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

	def input_step(file: get_test_data_file_path(PARCEL_FILE))
		Prima::TextFileInputStep.new(file)
	end

	def filter_step
		# Strip leading and trailing " character as the prelude to parsing out the CSV
		filter = Prima::RegexFilterStep.new(/^\"(.+)\"$/)	
	end

	def csv_step
		csv = Prima::CsvParserStep.new(header_row: false, options: { :quote_char => "\x00", :col_sep => "\",\"" })
	end

	def mapper_step
		Prima::MapperStep.define_mappings do |m|
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
