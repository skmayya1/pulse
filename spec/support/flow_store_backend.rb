class FlowStoreBackend
  attr_reader :values

  def initialize
    @values = {}
  end

  def write(key, value, expires_in:)
    values[key] = value
    true
  end

  def read(key)
    values[key]
  end

  def consume(key)
    values.delete(key)
  end
end
