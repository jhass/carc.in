require "./command"
require "./btrfs_subvolume_commands"

class Carcin::Sandbox::DropCommand
  include Command
  include BtrfsSubvolumeCommands

  def initialize(@confirm=true)
  end

  def execute(definition, version)
    path = path_to(definition, version)

    if File.exists? path
      delete_subvolume path
    else
      puts "#{path} does not exists, skip dropping."
    end

    path = wrapper_path(definition, version)
    File.delete(path) if File.exists? path

    path = whitelist_path(definition, version)
    File.delete(path) if File.exists? path
  end
end
