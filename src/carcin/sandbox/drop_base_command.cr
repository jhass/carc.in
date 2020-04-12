require "./command"
require "./btrfs_subvolume_commands"
require "./definition"

class Carcin::Sandbox::DropBaseCommand
  include Command
  include BaseCommand
  include BtrfsSubvolumeCommands

  def execute(definition, version = nil)
    case definition
    when "base"
      drop base_path
    when Definition
      drop base_path_for(definition.name)
    else
      # exhaustive
    end
  end

  def drop(path)
    if File.exists? path
      delete_subvolume path
    else
      puts "#{path} does not exists, skip dropping."
    end
  end
end
