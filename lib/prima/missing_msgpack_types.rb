# Monkey-patch some Ruby standard types so they serialize with MsgPack properly

require 'bigdecimal'

# Per https://github.com/msgpack/msgpack-ruby/issues/26 msgpack intentionally doesn't support BigDecimal for
# reasonably good reasons, however that's cold comfort for us left needing to serialize such values.
#
# This hack isn't perfect, as the value will deserialize from msgpack back to ruby as a float, not a bigdecimal,
# so there's potential loss of accuracy due to float weirdness, however it's better than nothing
BigDecimal.class_eval do
  def to_msgpack(*args)
    to_f.to_msgpack(*args)
  end
end

if defined?(DateTime)
  # Similar hack as above, but worse since the result will deserialize as a ISO 8601 representation of the date as a string
  # Implementors of ETL logic need to be aware of this or it will bite them in the ass
  DateTime.class_eval do
    def to_msgpack(*args)
      to_s.to_msgpack(*args)
    end
  end
end

Date.class_eval do
  def to_msgpack(*args)
    to_s.to_msgpack(*args)
  end
end

Time.class_eval do
  def to_msgpack(*args)
    to_s.to_msgpack(*args)
  end
end