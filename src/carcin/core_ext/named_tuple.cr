struct NamedTuple
  def fetch(key : String)
    {% for key in T %}
      return self[{{key.symbolize}}] if {{key.stringify}} == key
    {% end %}
    yield
  end
end
