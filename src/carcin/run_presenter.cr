require "json"

module Carcin
  class RunPresenter
    JSON.mapping({
      id:           String,
      language:     String,
      version:      {type: String, nilable: true},
      code:         String,
      stdout:       String,
      stderr:       String,
      exit_code:    Int32,
      created_at:   {type: Time, converter: Time::Format.new("%FT%TZ"), nilable: true},
      url:          String,
      html_url:     String,
      download_url: String
    })

    def initialize(run : Run)
      @id           = Carcin::Base36.encode run.id.not_nil!
      @language     = run.language
      @version      = run.version
      @code         = run.code
      @stdout       = run.stdout
      @stderr       = run.stderr
      @exit_code    = run.exit_code
      @created_at   = run.created_at
      @url          = "%s/runs/%s" % {Carcin::BASE_URL, @id}
      @html_url     = "%s/#/r/%s" % {Carcin::FRONTEND_URL, @id}
      file_extension = Carcin::Runner::RUNNERS[@language].short_name
      @download_url = "%s/runs/%s.%s" % {Carcin::BASE_URL, @id, file_extension}
    end
  end
end
