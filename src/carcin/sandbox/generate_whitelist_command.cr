require "./command"

class Carcin::Sandbox::GenerateWhitelistCommand
  include Command

  ifdef x86_64
    ALL_SYSCALLS_LIST = "all_syscalls64"
  else
    ALL_SYSCALLS_LIST = "all_syscalls32"
  end

  def initialize(@force=false)
  end

  def execute(definition, version)
    ensure_path_to definition

    whitelist = whitelist_path definition, version

    if File.exists?(whitelist)
      if @force
        File.delete(whitelist)
      else
        puts "Whitelist #{whitelist} exists, skipping."
        return
      end
    end

    abort "Sandbox not build for #{definition.name} #{version}" unless File.exists? path_to(definition, version)

    # Create & Truncate
    File.write(whitelist, "")

    puts "Generating learning mode wrapper"
    BuildWrapperCommand.new.execute(definition, version, true)

    definition.allowed_programs.each do |program|
      puts "Learn #{program}"
      run = Carcin::Runner.execute Carcin::RunRequest.new(definition.name, version, program, "sandbox.builder")
      unless run.successful?
        puts run.error?
        puts run.stderr
        puts run.stdout
      end
    end

    puts "Restoring normal wrapper"
    BuildWrapperCommand.new.execute(definition, version, false)
  end
end

