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

  get "/runs/:id.cr" do
    begin
      run = find_run params["id"]

      if run
        headers({
          "Content-Type": "text/plain; charset=utf8",
          "Content-Disposition": "attachment; filename=#{params["id"]}.cr"
        })
        status 200
        run.code
      else
        headers({"Content-Type": "text/plain"})
        status 404
        "Not found."
      end
    rescue e
      e.inspect_with_backtrace(STDERR)
      status 500
      headers({"Content-Type": "text/plain"})
      "Something went wrong, sorry."
    end
  end

  get "/runs/:id" do
    with_error_handling do
      run = find_run params["id"]

      if run
        json({"run": Carcin::RunPresenter.new(run)})
      else
        not_found
      end
    end
  end

  private def find_run(id)
    id = Carcin::Base36.decode id
    Carcin::Run.find_by_id(id) if id
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
    e.inspect_with_backtrace(STDERR)
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

port = ENV["PORT"]?.try(&.to_i?) || 8000
server = HTTP::Server.new(port) do |request|
  App.call(request)
end

puts "Carcin listening on #{port}"
server.listen
