require "json"
require "Moonshine/moonshine"
require "./carcin"

include Moonshine::Shortcuts

def Object.from_json? json
  from_json json
rescue e : JSON::ParseException
end

def json object
  ok(object.to_json).tap do |response|
    response.headers["Content-Type"] = "application/json"
  end
end

def json_error status, message
  Moonshine::Http::Response.new(
    status,
    %({"error": "#{message}"}),
    HTTP::Headers {"Content-Type" => "application/json"}
  )
end

def unprocessable message
  json_error 422, message
end

def not_found
  json_error 404, "not found"
end

app = Moonshine::App.new

app.error_handler 404 do |_request|
  json_error 404, "not found"
end

app.get "/" do |request|
  json({
    "languages_url": "#{Carcin::BASE_URL}/languages",
    "run_url": "#{Carcin::BASE_URL}/run/{id}",
    "run_request_url": "#{Carcin::BASE_URL}/run_request"
  })
end

app.get "/languages" do |request|
  json Carcin::Runner::RUNNERS.map {|name, runner|
    [name, runner.versions]
  }.reject(&.last.empty?).to_h
end

app.get "/run/:id" do |request|
  id  = Carcin::Base36.decode request.params["id"]
  run = Carcin::Run.find_by_id(id) if id

  if run
    json Carcin::RunPresenter.new(run)
  else
    not_found
  end
end

app.post "/run_request" do |request|
  begin
    if request.headers["Content-Type"] != "application/json"
      unprocessable "invalid content type"
    else
      run_request = Carcin::RunRequest.from_json? request.body
      if run_request
        run = Carcin::Runner.execute run_request
        if run.save
          json Carcin::RunPresenter.new(run)
        else
          unprocessable run.error
        end
      else
        unprocessable "can't parse request"
      end
    end
  rescue e
    puts e.class
    puts e.message
    puts e.backtrace.join("\n")
    json_error 500, "internal server error"
  end
end

app.run
