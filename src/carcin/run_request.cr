require "json"

module Carcin
  class RunRequest
    json_mapping({
      language: String,
      version:  {type: String, nilable: true}
      code:     String
    }, true)

    def initialize(@language, @version, @code)
    end
  end
end
