require "json"

module Carcin
  class RunPresenter
    json_mapping({
      language:   String,
      version:    String,
      code:       String,
      stdout:     String,
      stderr:     String,
      created_at: {type: Time, converter: TimeFormat.new("%F %T")}
    })

    def initialize(run : Run)
      @language   = run.language
      @version    = run.version
      @code       = run.code
      @stdout     = run.stdout
      @stderr     = run.stderr
      @created_at = run.created_at
    end
  end
end
