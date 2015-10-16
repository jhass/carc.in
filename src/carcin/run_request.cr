require "json"

module Carcin
  class RunRequest
    JSON.mapping({
      language: String,
      version:  {type: String, nilable: true},
      code:     String
    }, true)

    property author_ip

    def initialize(@language, @version, @code, @author_ip)
    end
  end
end
