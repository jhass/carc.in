require "pg"

module Carcin
  BASE_URL = ENV["BASE_URL"]? || "http://carc.in"
  SANDBOX_BASEPATH = File.expand_path File.join(__DIR__, "..", "sandboxes")

  def self.db
    @@db ||= PG.connect("postgres:///carc")
  end
end

require "./carcin/*"
