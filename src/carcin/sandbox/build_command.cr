require "./command"
require "./btrfs_subvolume_commands"
require "./package_manager"
require "./build_base_command"
require "./build_wrapper_command"
require "./generate_whitelist_command"

class Carcin::Sandbox::BuildCommand
  include Command
  include BtrfsSubvolumeCommands
  include PackageManager

  def execute(definition, version)
    path = path_to(definition, version)

    if File.exists? path
      puts "#{definition.name} #{version} exists, skipping."
      return
    end

    BuildBaseCommand.new.execute definition

    ensure_path_to definition
    ensure_package_exists path, definition.name, version, definition.split_packages
    create_snapshot base_path_for(definition.name), path
    install_package path, definition.name, version, definition.split_packages

    BuildWrapperCommand.new.execute(definition, version)
    GenerateWhitelistCommand.new.execute(definition, version)
  end
end

