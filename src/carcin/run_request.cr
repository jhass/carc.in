require "json"

module Carcin
  class RunRequest
    json_mapping({
      language: String,
      version:  {type: String, nilable: true}
      code:     String
    }, true)
  end
end
