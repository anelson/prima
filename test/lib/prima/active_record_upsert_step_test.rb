require 'test_helper'

class ActiveRecordUpsertStepTest < EtlTestCase
	test "given an existing record with no changes, does nothing" do
		skip("TODO: Figure out how to do this outside of  rails project since ActiveRecord and our models don't exist")
		existing_record = parcels(:initial_parcel)
		created = existing_record.created_at
		updated = existing_record.updated_at

		input = [
			{ 'data' => existing_record.attributes.select { |k,v| k != 'id' && k != 'created_at' && k != 'updated_at' } }
		]

		step = Prima::ActiveRecordUpsertStep.new(Parcel, ['folio'])

		run_sink_step(input, step)

		resulting_record = Parcel.find(existing_record.id)

		assert_equal existing_record.attributes, resulting_record.attributes
	end

	test "given an existing record with changes, applies the change" do
		skip("TODO: Figure out how to do this outside of  rails project since ActiveRecord and our models don't exist")
		existing_record = parcels(:initial_parcel)
		created = existing_record.created_at
		updated = existing_record.updated_at

		input = [
			{ 'data' => existing_record.attributes.select { |k,v| k != 'id' && k != 'created_at' && k != 'updated_at' } }
		]

		input[0]['data']['owner1'] = "new owner"

		step = Prima::ActiveRecordUpsertStep.new(Parcel, ['folio'])

		run_sink_step(input, step)

		resulting_record = Parcel.find(existing_record.id)

		skip("upsert doesn't update the time stamps so need to figure out a way to handle that")

		assert_equal created, resulting_record.created_at
		assert_operator resulting_record.updated_at, :>, updated
		assert_equal "new owner", resulting.record.owner1
	end

	test "given a new record, inserts" do
		skip("TODO: Figure out how to do this outside of  rails project since ActiveRecord and our models don't exist")
		existing_record = parcels(:initial_parcel)
		existing_record.folio = "XXXXX"

		input = [
			{ 'data' => existing_record.attributes.select { |k,v| k != 'id' && k != 'created_at' && k != 'updated_at' } }
		]

		input[0]['data']['owner1'] = "new owner"

		step = Prima::ActiveRecordUpsertStep.new(Parcel, ['folio'])

		run_sink_step(input, step)

		assert_equal 2, Parcel.count(:all)

		resulting_record = Parcel.where(:folio => "XXXXX").first

		assert_equal "new owner", resulting_record.owner1

		skip("upsert doesn't update the time stamps so need to figure out a way to handle that")

		assert_equal created, resulting_record.created_at
		assert_operator resulting_record.updated_at, :>, updated
	end
end
