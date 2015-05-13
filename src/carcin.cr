module Carcin
  BASE_URL = ENV["BASE_URL"]? || "http://carc.in"
  SANDBOX_BASEPATH = File.expand_path File.join(__DIR__, "..", "sandboxes")
end

require "./carcin/*"
