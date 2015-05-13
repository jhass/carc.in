module Carcin
  class Run
    getter! error
    getter  language
    getter  version
    getter  code
    getter  stdout
    getter  stderr
    getter  exit_code
    getter  created_at

    class Failed < Run
      def initialize(request, @error)
        super request, "", "", 1
      end

      def save
        false
      end
    end

    def self.failed_for request, message
      Failed.new request, message
    end

    def self.find_by_id id
      new id, "crystal", "0.7.1", %(puts "hello world"), "test", "test", 0, Time.now
    end

    def initialize(@id, @language, @version, @code, @stdout, @stderr, @exit_code, @created_at)
    end

    def initialize(request, @stdout, @stderr, @exit_code)
      @language = request.language
      @version  = request.version
      @code     = request.code
    end

    def signal
      @stderr.match(/with signal (\d+)/).try &.[1].to_i
    end

    def successful?
      return false if @stderr.includes?("Bad system call")
      return false if @stderr.includes?("timeout triggered!")
      return false if @stdout.includes?("error code: 31")
      return false if signal

      @exit_code == 0
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

