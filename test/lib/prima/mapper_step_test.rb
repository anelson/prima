require 'test_helper'

class MapperStepTest < EtlTestCase
	def setup
		@hash_input = [
			{ 'data' => { 'name' => 'dick', 'age' => 5, 'id' => 50000 } },
			{ 'data' => { 'name' => 'bob', 'age' => 10, 'id' => 50001 } },
			{ 'data' => { 'name' => 'cornelious', 'age' => 15, 'id' => 50002 } }
		]

		@array_input = [
			{ 'data' => [ 'dick', 5, 50000 ] },
			{ 'data' => [ 'bob', 10, 50001 ] },
			{ 'data' => [ 'cornelious', 15, 50002 ] }
		]
	end

	test "produces empty row if no mappings defined" do
		step = MapperStep.define_mappings do |m|
		end

		output = run_transform_step(@hash_input, step)

		assert_equal [
			{ 'data' => {  } },
			{ 'data' => {  } },
			{ 'data' => {  } } ], output
	end

	test "maps values by ordinal" do
		step = MapperStep.define_mappings do |m|
			m.map_ordinal 0, 'name'
			m.map_ordinal 1, 'age'
			m.map_ordinal 2, 'id'
		end

		output = run_transform_step(@array_input, step)

		assert_equal @hash_input, output
	end

	test "maps values by array of labels" do
		step = MapperStep.define_mappings do |m|
			m.map_ordinal_by_array ['name', 'age', 'id']
		end

		output = run_transform_step(@array_input, step)

		assert_equal @hash_input, output
	end

	test "maps values by name" do
		step = MapperStep.define_mappings do |m|
			m.map_name 'name', 'designation'
			m.map_ordinal 'age', 'runtime'
		end

		output = run_transform_step(@hash_input, step)

		assert_equal [
			{ 'data' => { 'designation' => 'dick', 'runtime' => 5 } },
			{ 'data' => { 'designation' => 'bob', 'runtime' => 10 } },
			{ 'data' => { 'designation' => 'cornelious', 'runtime' => 15 } }
		], output
	end

	test "maps values by a user defined hash" do
		step = MapperStep.define_mappings do |m|
			m.map Hash[{
				'name' => 'designation',
				'age' => 'runtime'
			}]
		end

		output = run_transform_step(@hash_input, step)

		assert_equal [
			{ 'data' => { 'designation' => 'dick', 'runtime' => 5 } },
			{ 'data' => { 'designation' => 'bob', 'runtime' => 10 } },
			{ 'data' => { 'designation' => 'cornelious', 'runtime' => 15 } }
		], output
	end

	test "maps values with custom block" do
		step = MapperStep.define_mappings do |m|
			m.map_custom do |row|
				{ 'whatever' => row['age'] }
			end
		end

		output = run_transform_step(@hash_input, step)

		assert_equal [
			{ 'data' => { 'whatever' => 5 } },
			{ 'data' => { 'whatever' => 10 } },
			{ 'data' => { 'whatever' => 15 } }
		], output
	end

	test "fails if an input does not exist" do 
		step = MapperStep.define_mappings do |m|
			m.map_name 'name', 'designation'
			m.map_ordinal 'salary', 'runtime'
		end

		assert_raise RuntimeError do 
			run_transform_step(@hash_input, step)
		end
	end
end
