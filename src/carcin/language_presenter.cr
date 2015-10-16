module Carcin
  class LanguagePresenter
    JSON.mapping({
      id: String,
      name: String,
      versions: Array(String)
    }, true)

    def initialize(@name, runner)
      @id       = runner.short_name
      @versions = runner.versions
    end
  end
end
