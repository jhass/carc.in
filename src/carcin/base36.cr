module Carcin
  module Base36
    extend self

    def encode number
      number.to_s(36).downcase
    end

    def decode base36
      LibC.strtoull(base36.upcase, nil, 36)
    end
  end
end
