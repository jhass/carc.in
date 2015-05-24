module Enumerable
  def find_value(fallback=nil)
    each do |item|
      value = yield item
      return value if value
    end
    fallback
  end
end

