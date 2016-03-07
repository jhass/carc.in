require "./definition"

module Carcin::Sandbox
  module Command
    def run(language, version)
      if language == "all"
        languages.each do |language|
          run language, version
        end

        return
      end

      if language == "base"
        execute_base
      else
        if version == "all"
          versions_for(language).each do |version|
            execute definition_for(language), version
          end

          return
        end

        unless languages.includes? language
          abort "No definition for #{language}"
        end

        unless version.nil? || versions_for(language).includes? version
          abort "No definition for #{language} #{version}"
        end

        execute definition_for(language), version
      end
    end

    def execute_base
      abort "This is not a base command."
    end

    def versions_for(language)
      definition_for(language).try(&.versions) || [] of String
    end

    def definition_for(language)
      definition = definitions.find(&.name.==(language))
      raise "No definition found for #{language}" unless definition
      definition
    end

    def languages
      definitions.map &.name
    end

    def definitions
      @definitions ||= Dir["#{Carcin::SANDBOX_BASEPATH}/definitions/*.json"].map {|path|
        begin
          Definition.from_json File.read(path)
        rescue e
          abort "Failed to parse #{path}: #{e.message}."
        end
      }
    end

    def ensure_path_to(definition)
      Dir.mkdir_p path_to(definition)
    end

    def path_to(definition, version=nil)
      path = File.join Carcin::SANDBOX_BASEPATH, definition.name
      version ? File.join(path, version) : path
    end

    def base_path
      File.join Carcin::SANDBOX_BASEPATH, "bases", "base"
    end

    def base_path_for(language)
      File.join Carcin::SANDBOX_BASEPATH, "bases", language
    end

    def wrapper_path(definition, version)
      File.join path_to(definition), "sandboxed_#{definition.name}#{version}"
    end

    def whitelist_path(definition, version)
      File.join path_to(definition), "sandbox_whitelist#{version}"
    end

    def chrooted_system(chroot, command)
      system %(arch-chroot "#{chroot}" #{command})
    end
  end

  module BaseCommand
    def execute_base
      execute "base"
    end
  end
end
