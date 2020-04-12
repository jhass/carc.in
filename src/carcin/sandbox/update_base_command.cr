require "./command"
require "./drop_base_command"
require "./build_base_command"

class Carcin::Sandbox::UpdateBaseCommand
  include Command
  include BaseCommand

  def execute(definition, version = nil)
    case definition
    when "base"
      update base_path
    when Definition
      update base_path
      DropBaseCommand.new.execute definition
      BuildBaseCommand.new.execute definition
    else
      # exhaustive
    end
  end

  def update(path)
    if File.exists? path
      chrooted_system path, "pacman -Syu --noconfirm"
    else
      abort "Can't update #{path}: no such directory."
    end
  end
end
