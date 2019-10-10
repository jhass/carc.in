module Carcin
  class Run
    getter! error
    getter  id : Int32?
    getter  language : String
    getter  version : String?
    getter  code : String
    getter  stdout : String
    getter  stderr : String
    getter  exit_code : Int32
    getter  author_ip : String
    getter  created_at : Time?

    class Failed < Run
      def initialize(request, @error)
        super request, "", "", 1
      end

      def save
        false
      end
    end

    def self.failed_for(request, message)
      Failed.new request, message
    end

    def self.from_request_and_status(request, status)
      new status.output, status.error, status.exit_code
    end

    def self.find_by_id(id)
      Carcin.db.query_one?(
        "SELECT id, language, version, code, stdout, stderr, exit_code, author_ip, created_at AT TIME ZONE 'UTC' AS created_at
         FROM runs
         WHERE id = $1",
        id
      ) do |result|
        new result.read(Int32),
            result.read(String),
            result.read(String),
            result.read(String),
            result.read(String),
            result.read(String),
            result.read(Int32),
            result.read(String),
            result.read(Time)
      end
    end

    def initialize(request, status)
      initialize(
        request,
        status.output,
        status.error,
        status.exit_code
      )
    end

    def initialize(request, stdout, stderr, exit_code)
      initialize(
        nil,
        request.language,
        request.version,
        request.code,
        stdout,
        stderr,
        exit_code,
        request.author_ip.to_s,
        nil
      )
    end

    def initialize(@id, @language, @version, @code, @stdout, @stderr, @exit_code, @author_ip, @created_at)
    end

    def signal
      @stderr.match(/with signal (\d+)/).try &.[1].to_i
    end

    def successful?
      return false if @stderr.includes?("Bad system call")
      return false if @stderr.includes?("timeout triggered!")
      return false if @stdout.includes?("error code: 31")
      return false if @stdout.includes?("execution of command failed with code:")
      return false if signal

      @exit_code == 0
    end

    def save
      if @version.nil?
        @error = "no version available"
        false
      else
        Carcin.db.query_one(
          "INSERT INTO runs (language, version, code, stdout, stderr, exit_code, author_ip)
           VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id, created_at AT TIME ZONE 'UTC' AS created_at",
          @language, @version, @code, @stdout, @stderr, @exit_code, @author_ip
        ) do |result|
          @id         = result.read(Int32)
          @created_at = result.read(Time)
        end
        true
      end
    end
  end
end

