module Carcin
  class Run
    getter! error
    getter  language
    getter  version
    getter  code
    getter  stdout
    getter  stderr
    getter  created_at

    class Failed < Run
      def initialize(request, @error)
        super request, "", ""
      end

      def save
        false
      end
    end

    def self.failed_for request, message
      Failed.new request, message
    end

    def self.find_by_id id
      new id, "crystal", "0.7.1", %(puts "hello world"), "test", "test", Time.now
    end

    def initialize(@id, @language, @version, @code, @stdout, @stderr, @created_at)
    end

    def initialize(request, @stdout, @stderr)
      @language = request.language
      @version  = request.version
      @code     = request.code
    end

    def save
      @created_at = Time.now

      if version.nil?
        @error = "no version available"
        false
      else
        true
      end
    end
  end
end

