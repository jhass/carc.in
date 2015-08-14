lib LibC
  fun getuid() : Int32
  fun setuid(uid : Int32) : Int32
end

def Process.uid
  LibC.getuid
end

def Process.uid=(uid)
  unless LibC.setuid(uid.to_i32) == 0
    raise Errno.new "Can't switch to user #{uid}"
  end

  uid.to_i32
end

class Process::Status
  property stderr
end

def Process.run(command, args = nil, output = nil : IO | Bool, input = nil : String | IO, stderr = nil : IO | Bool)
  argv = [command.cstr]
  if args
    args.each do |arg|
      argv << arg.cstr
    end
  end
  argv << Pointer(UInt8).null

  if output
    process_output, fork_output = IO.pipe
  end

  if stderr
    process_stderr, fork_stderr = IO.pipe
  end

  if input
    fork_input, process_input = IO.pipe
  end

  pid = fork do
    if output == false
      null = File.new("/dev/null", "r+")
      STDOUT.reopen(null)
    elsif fork_output
      STDOUT.reopen(fork_output)
    end

    if stderr == false
      null = File.new("/dev/null", "r+")
      STDERR.reopen(null)
    elsif fork_stderr
      STDERR.reopen(fork_stderr)
    end

    if process_input && fork_input
      process_input.close
      STDIN.reopen(fork_input)
    end


    LibC.execvp(command, argv.buffer)
    LibC.exit 127
  end

  if pid == -1
    raise Errno.new("Error executing system command '#{command}'")
  end

  status = Process::Status.new(pid)

  if input
    process_input = process_input.not_nil!
    fork_input.not_nil!.close

    case input
    when String
      process_input.print input
      process_input.close
      process_input = nil
    when IO
      input_io = input
    end
  end

  if output
    fork_output.not_nil!.close

    case output
    when true
      status_output = StringIO.new
    when IO
      status_output = output
    end
  end

  if stderr
    fork_stderr.not_nil!.close

    case stderr
    when true
      status_stderr = StringIO.new
    when IO
      status_stderr = stderr
    end
  end


  while process_input || process_output || process_stderr
    wios = nil
    rios = nil

    if process_input
      wios = {process_input}
    end

    if process_output
      rios = {process_output}
    end

    if process_stderr
      rios = {process_stderr}
    end

    buffer :: UInt8[2048]

    ios = IO.select(rios, wios)
    next unless ios

    if process_input && ios.includes? process_input
      bytes = input_io.not_nil!.read(buffer.to_slice)
      if bytes == 0
        process_input.close
        process_input = nil
      else
        process_input.write(buffer.to_slice, bytes)
      end
    end

    if process_output && ios.includes? process_output
      bytes = process_output.read(buffer.to_slice)
      if bytes == 0
        process_output.close
        process_output = nil
      else
        status_output.not_nil!.write(buffer.to_slice, bytes)
      end
    end

    if process_stderr && ios.includes? process_stderr
      bytes = process_stderr.read(buffer.to_slice)
      if bytes == 0
        process_stderr.close
        process_stderr = nil
      else
        status_stderr.not_nil!.write(buffer.to_slice, bytes)
      end
    end
  end

  status.exit = Process.waitpid(pid)

  if output == true
    status.output = status_output.to_s
  end

  if stderr == true
    status.stderr = status_stderr.to_s
  end

  $? = status

  status
end
