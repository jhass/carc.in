module Carcin
  module Base36
    extend self

    def encode(number)
      number.to_s(36).downcase
    end

    def decode(base36)
      base36.upcase.to_i64?(36)
    end
  end
end
