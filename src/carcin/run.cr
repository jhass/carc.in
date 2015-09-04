module Carcin
  class Run
    getter! error
    getter  id
    getter  language
    getter  version
    getter  code
    getter  stdout
    getter  stderr
    getter  exit_code
    getter  author_ip
    getter  created_at

    class Failed < Run
      def initialize request, @error
        super request, "", "", 1
      end

      def save
        false
      end
    end

    def self.failed_for request, message
      Failed.new request, message
    end

    def self.from_request_and_status request, status
      new status.output, status.error, status.exit_code
    end

    def self.find_by_id id
      result = Carcin.db.exec(
        "SELECT id, language, version, code, stdout, stderr, exit_code, author_ip, created_at AT TIME ZONE 'UTC' AS created_at
         FROM runs
         WHERE id = $1",
        [id]
      )

      unless result.rows.empty?
        row = result.to_hash.first
        new row["id"] as Int32,
            row["language"] as String,
            row["version"] as String,
            row["code"] as String,
            row["stdout"] as String,
            row["stderr"] as String,
            row["exit_code"] as Int32,
            row["author_ip"] as String,
            row["created_at"] as Time
      end
    end

    def initialize request, status
      initialize(
        request,
        status.output,
        status.error,
        status.exit_code
      )
    end

    def initialize request, stdout, stderr, exit_code
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
      return false if signal

      @exit_code == 0
    end

    def save
      if @version.nil?
        @error = "no version available"
        false
      else
        result = Carcin.db.exec(
          "INSERT INTO runs (language, version, code, stdout, stderr, exit_code, author_ip)
           VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id, created_at AT TIME ZONE 'UTC' AS created_at",
          [@language, @version, @code, @stdout, @stderr, @exit_code, @author_ip]
        ).rows.first
        @id         = result[0] as Int32
        @created_at = result[1] as Time
        true
      end
    end
  end
end

