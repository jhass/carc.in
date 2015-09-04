require "json"

module Carcin
  class RunPresenter
    json_mapping({
      id:           String,
      language:     String,
      version:      String,
      code:         String,
      stdout:       String,
      stderr:       String,
      exit_code:    Int32,
      created_at:   {type: Time, converter: TimeFormat.new("%FT%TZ")},
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
      @download_url = "%s/runs/%s.cr" % {Carcin::BASE_URL, @id}
    end
  end
end
