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

    whitelist       = whitelist_path definition, version
    all_syscalls    = File.read_lines File.join(Carcin::SANDBOX_BASEPATH, "definitions", ALL_SYSCALLS_LIST)
    needed_syscalls = all_syscalls.dup

    if File.exists?(whitelist) && !@force
      puts "Whitelist #{whitelist} exists, skipping."
      return
    end

    abort "Sandbox not build for #{definition.name} #{version}" unless File.exists? path_to(definition, version)
    abort "Wrapper not build for #{definition.name} #{version}" unless File.exists? wrapper_path(definition, version)

    all_syscalls.each_with_index do |syscall, i|
      puts "Try without #{syscall.strip} (#{i+1}/#{all_syscalls.size})"
      File.write whitelist, (needed_syscalls - [syscall]).join
      if test_programs definition, version
        needed_syscalls = needed_syscalls - [syscall]
        puts "Removing #{syscall.strip} (#{all_syscalls.size-needed_syscalls.size} dropped)"
      else
        puts "Keeping #{syscall.strip} (#{needed_syscalls.size} in whitelist)"
      end
    end
  end

  def test_programs(definition, version)
    definition.allowed_programs.each do |program|
      run = Carcin::Runner.execute Carcin::RunRequest.new(definition.name, version, program, "sandbox.builder")
      puts "Exited with #{run.exit_code} for: #{program}"
      return false unless run.successful?
    end

    definition.allowed_failing_programs.each do |program|
      run = Carcin::Runner.execute Carcin::RunRequest.new(definition.name, version, program, "sandbox.builder")
      puts "Exited with #{run.exit_code} for: #{program}"
      if run.stderr.starts_with?("playpen")
        return false if (run.signal && run.signal == 31) || run.stderr.includes?("timeout triggered!")
      elsif run.stderr.includes?("Bad system call")
        return false
      end
    end

    true
  end
end

