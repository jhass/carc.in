require "json"
require "Moonshine/moonshine"
require "./carcin"

include Moonshine::Shortcuts

def Object.from_json? json, root=nil
  if root
    object = JSON.parse(json) as Hash(String, JSON::Type)
    object = object[root]?
    json = object.to_json if object
  end
  from_json json
rescue e : JSON::ParseException
end

module Enumerable
  def find_value(fallback=nil)
    each do |item|
      value = yield item
      return value if value
    end
    fallback
  end
end

def json object
  ok(object.to_pretty_json).tap do |response|
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    response.headers["Access-Control-Allow-Origin"] = "*"
  end
end

def json_error status, message
  Moonshine::Http::Response.new(
    status,
    %({"error": {"message": "#{message}"}}),
    HTTP::Headers {
      "Content-Type" => "application/json; charset=utf-8",
      "Access-Control-Allow-Origin" => "*"
    }
  )
end

def unprocessable message
  json_error 422, message
end

def not_found
  json_error 404, "not found"
end

def client_ip headers
  {"CLIENT_IP", "X_FORWARDED_FOR", "X_FORWARDED", "X_CLUSTER_CLIENT_IP", "FORWARDED"}.find_value {|header|
    dashed_header = header.tr("_", "-")
    headers[header]? || headers[dashed_header]? || headers["HTTP_#{header}"]? || headers["Http-#{dashed_header}"]?
  }.try &.split(',').first
end

app = Moonshine::App.new

app.error_handler 404 do |_request|
  json_error 404, "not found"
end

app.get "/" do |request|
  json({
    "languages_url": "#{Carcin::BASE_URL}/languages",
    "run_url": "#{Carcin::BASE_URL}/runs/{id}",
    "run_request_url": "#{Carcin::BASE_URL}/run_requests"
  })
end

app.get "/languages" do |request|
  json({"languages": Carcin::Runner::RUNNERS.map {|name, runner|
    Carcin::LanguagePresenter.new(name, runner)
  }.reject(&.versions.empty?)})
end

app.get "/runs/:id" do |request|
  begin
    id  = Carcin::Base36.decode request.params["id"]
    run = Carcin::Run.find_by_id(id) if id

    if run
      json({"run": Carcin::RunPresenter.new(run)})
    else
      not_found
    end
  rescue e
    puts e.class
    puts e.message
    puts e.backtrace.join("\n")
    json_error 500, "internal server error"
  end
end

app.request_middleware do |request|
  if request.method == "OPTIONS"
    Moonshine::MiddlewareResponse.new(
      Moonshine::Http::Response.new(
        204,
        "",
        HTTP::Headers {
          "Access-Control-Allow-Origin" => "*",
          "Access-Control-Allow-Methods" => "GET, POST, PATCH, PUT, DELETE",
          "Access-Control-Allow-Headers" => "Content-Type"
        }
      ),
      pass_through: false
    )
  else
    Moonshine::MiddlewareResponse.new
  end
end

app.post "/run_requests" do |request|
  begin
    if request.headers["Content-Type"].starts_with? "application/json"
      run_request = Carcin::RunRequest.from_json? request.body, "run_request"
      if run_request
        run_request.author_ip = client_ip request.headers
        run = Carcin::Runner.execute run_request
        if run.save
          json({"run_request": {"run": Carcin::RunPresenter.new(run)}})
        else
          unprocessable run.error
        end
      else
        unprocessable "can't parse request"
      end
    else
      unprocessable "invalid content type"
    end
  rescue e
    puts e.class
    puts e.message
    puts e.backtrace.join("\n")
    json_error 500, "internal server error"
  end
end

app.run
