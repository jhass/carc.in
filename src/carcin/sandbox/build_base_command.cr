require "./command"
require "./btrfs_subvolume_commands"
require "./package_builder"
require "./definition"

class Carcin::Sandbox::BuildBaseCommand
  include Command
  include BaseCommand
  include BtrfsSubvolumeCommands
  include PackageBuilder

  BASE_PACKAGES = %w(bash coreutils shadow file grep sed pacman lz4)

  def execute(definition, version=nil)
    Dir.mkdir_p File.dirname(base_path)

    case definition
    when "base"
      build_base
    when Definition
      build_base
      build definition
    end
  end

  def build_base
    if File.exists? base_path
      puts "base exists, skipping."
      return
    end

    create_subvolume base_path
    pacstrap base_path, BASE_PACKAGES
    File.open(File.join(base_path, "etc/locale.gen"), "a") do |io|
      io.puts "\nen_US.UTF-8 UTF-8"
    end
    File.write File.join(base_path, "etc/locale.conf"), "LANG=en_US.UTF-8"
    Dir.mkdir_p File.join(base_path, "dev/shm")
    system "mknod -m666 #{File.join(base_path, "dev/null")} c 1 3"
    system "mknod -m444 #{File.join(base_path, "dev/random")} c 1 8"
    system "mknod -m444 #{File.join(base_path, "dev/urandom")} c 1 9"
    chrooted_system base_path, "locale-gen"
  end

  def build(definition)
    path = base_path_for(definition.name)
    if File.exists? path
      puts "base for #{definition.name} exists, skipping."
      return
    end

    create_snapshot base_path, path
    create_user path, definition.name
    pacstrap path, definition.dependencies
    definition.aur_dependencies.each do |name|
      build_package name
      install_package path, name
    end
  end

  def pacstrap(path, packages)
    system("pacstrap -cd #{path} #{packages.join(' ')}")
  end


  def create_user(chroot, name)
    chrooted_system chroot, "useradd -m #{name}"
  end
end
