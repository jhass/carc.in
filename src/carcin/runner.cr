require "./core_ext/process"

module Carcin
  module Runner
    RUNNERS = {} of String => Runner

    def self.execute request
      runner = RUNNERS[request.language]?
      if runner
        runner.execute request
      else
        Run.failed_for request, "unsupported language"
      end
    end

    def self.register language, klass
      RUNNERS[language] = klass
    end

    def capture executable, params
      Process.run executable, params, output: true, stderr: true
    end

    abstract def execute request
    abstract def versions

    class Crystal
      include Runner

      SANDBOX_BASEPATH = File.join Carcin::SANDBOX_BASEPATH, "crystal"

      def execute request
        return Run.failed_for request, "no version available" if versions.empty?

        version = request.version || versions.first
        request.version = version
        if versions.includes? version
          status = capture executable_for(version), ["eval", request.code]
          Run.new request, status
        else
          Run.failed_for request, "unsupported version"
        end
      end

      def versions
        @versions ||= Dir["#{SANDBOX_BASEPATH}/*/"].map {|path| File.basename(path) }.sort.reverse
      end

      private def executable_for version
        File.join SANDBOX_BASEPATH, "sandboxed_crystal#{version}"
      end
    end

    register "crystal", Crystal.new
  end
end
