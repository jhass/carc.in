require "json"

module Carcin
  class RunPresenter
    json_mapping({
      language:   String,
      version:    String,
      code:       String,
      stdout:     String,
      stderr:     String,
      exit_code:  Int32,
      created_at: {type: Time, converter: TimeFormat.new("%F %T")}
    })

    def initialize(run : Run)
      @language   = run.language
      @version    = run.version
      @code       = run.code
      @stdout     = run.stdout
      @stderr     = run.stderr
      @exit_code  = run.exit_code
      @created_at = run.created_at
    end
  end
end
