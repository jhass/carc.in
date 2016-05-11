require "pg"

module Carcin
  BASE_URL         = ENV["BASE_URL"]? || "https://carc.in"
  FRONTEND_URL     = ENV["FRONTEND_URL"]? || BASE_URL
  SANDBOX_BASEPATH = File.expand_path File.join(__DIR__, "..", "sandboxes")
  @@db : PG::Connection?

  def self.db
    @@db ||= PG.connect("postgres:///#{ENV["DB"]? || "carcin"}")
  end
end

require "./carcin/*"
