require "http/server"

require "artanis"

require "./carcin"
require "./carcin/core_ext/enumerable"
require "./carcin/core_ext/json"


class App < Artanis::Application
  options "*" do
    status 204
    headers({
      "Access-Control-Allow-Origin":  "*",
      "Access-Control-Allow-Methods": "GET, POST, PATCH, PUT, DELETE",
      "Access-Control-Allow-Headers": "Content-Type"
    })
    ""
  end

  get "/" do
    json({
      "languages_url": "#{Carcin::BASE_URL}/languages",
      "run_url": "#{Carcin::BASE_URL}/runs/{id}",
      "run_request_url": "#{Carcin::BASE_URL}/run_requests"
    })
  end

  get "/languages" do
    json({"languages": Carcin::Runner::RUNNERS.map {|name, runner|
      Carcin::LanguagePresenter.new(name, runner)
    }.reject(&.versions.empty?)})
  end

  get "/runs/:id" do
    with_error_handling do
      id  = Carcin::Base36.decode params["id"]
      run = Carcin::Run.find_by_id(id) if id

      if run
        json({"run": Carcin::RunPresenter.new(run)})
      else
        not_found
      end
    end
  end

  post "/run_requests" do
    return unprocessable("invalid content type") unless request.headers["Content-Type"].starts_with? "application/json"

    body = request.body
    return unprocessable("no body") unless body

    run_request = Carcin::RunRequest.from_json? body, "run_request"
    return unprocessable("can't parse request") unless run_request

    with_error_handling do
      run_request.author_ip = client_ip
      run = Carcin::Runner.execute run_request
      if run.save
        json({"run_request": {"run": Carcin::RunPresenter.new(run)}})
      else
        unprocessable run.error
      end
    end
  end

  private def client_ip
    headers = request.headers
    {"CLIENT_IP", "X_FORWARDED_FOR", "X_FORWARDED", "X_CLUSTER_CLIENT_IP", "FORWARDED"}.find_value {|header|
      dashed_header = header.tr("_", "-")
      headers[header]? || headers[dashed_header]? || headers["HTTP_#{header}"]? || headers["Http-#{dashed_header}"]?
    }.try &.split(',').first
  end

  private def unprocessable message
    error 422, message
  end

  private def not_found
    error 404, "not found"
  end

  private def no_such_route
    body not_found
  end

  private def with_error_handling
    yield
  rescue e
    puts e.class
    puts e.message
    puts e.backtrace.join("\n")
    error 500, "internal server error"
  end

  private def error code, message
    json({"error": {"message": message}}, code)
  end

  private def json object, code=200
    headers({
      "Content-Type":                "application/json; charset=utf-8",
      "Access-Control-Allow-Origin": "*"
    })
    status code
    object.to_json
  end
end

port = ENV["PORT"]?.try(&.to_i) || 8000
server = HTTP::Server.new(port) do |request|
  App.call(request)
end

puts "Carcin listening on #{port}"
server.listen
