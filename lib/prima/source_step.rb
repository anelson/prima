module Prima
	# Base class for source steps, that produce their own inputs, like files, database, etc
	class SourceStep < EtlStep
		include MsgpackOutput
	end
end