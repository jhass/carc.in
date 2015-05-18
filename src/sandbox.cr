require "tempfile"
require "ecr/macros"
require "./carcin"

lib LibC
  fun getuid() : Int32
  fun setuid(uid : Int32) : Int32
end

if LibC.getuid != 0
  abort "This command must be run with root permissions."
end

def has_command command
  system("which #{command} 2>/dev/null >/dev/null")
end

{"btrfs", "pacstrap", "arch-chroot", "makepkg", "updpkgsums", "yaourt", "playpen"}.each do |tool|
  unless has_command(tool)
    abort "This command needs the #{tool} tool."
  end
end

fs_type = `df -T #{Carcin::SANDBOX_BASEPATH}`.lines.last.split[1]
unless fs_type == "btrfs"
  abort "#{Carcin::SANDBOX_BASEPATH} must be on a btrfs filesystem."
end

class SandboxDefinition
  json_mapping({
    name:                     String,
    versions:                 Array(String),
    dependencies:             Array(String),
    aur_dependencies:         Array(String),
    timeout:                  Int32,
    memory:                   {type: Int32, nilable: true},
    allowed_programs:         Array(String),
    allowed_failing_programs: Array(String)
  }, true)
end

class Cli
  ARGUMENT_DEFAULTS = {
    language: {
      "build-base": "base",
      "drop-base":  "base",
      "update":     "base"
    },
    version: {
      "build-base":         nil,
      "drop-base":          nil,
      "update":             nil,
      "update":             "all",
      "build":              "all",
      "drop":               "all",
      "rebuild":            "all",
      "build-wrapper":      "all",
      "generate-whitelist": "all"
    }
  }

  def initialize arguments
    help if (arguments & %w(help -h --help)).any? || arguments.size <= 1

    @command  = arguments[0]
    @language = arguments[1]? || ARGUMENT_DEFAULTS[:language].fetch(@command) { help }
    @version  = arguments[2]? || ARGUMENT_DEFAULTS[:version].fetch(@command) { help }
  end

  def run commands
    command = commands.fetch(@command) { help }
    command.run(@language, @version)
  end

  def help
    puts "Build and manage sandboxes"
    puts
    puts "  help, -h, --help                                         Display this."
    puts "  build-base         <language>|[base]                     Build base chroot."
    puts "  drop-base          <language>|[base]                     Drop base chroot."
    puts "  update             <language>|all|[base] <version>|[all] Update base chroot and rebuild (all) sandboxes."
    puts "  build              <language>|all        <version>|[all] Build (all) sandboxes."
    puts "  drop               <language>|all        <version>|[all] Drop (all) sandboxes."
    puts "  rebuild            <language>|all        <version>|[all] Rebuild (all) sandboxes."
    puts "  build-wrapper      <language>|all        <version>|[all] (Re)build (all) playpen wrappers."
    puts "  generate-whitelist <language>|all        <version>|[all] Generate new syscall whitelist."
    puts
    exit 0
  end
end

module Command
  def run language, version
    if language == "all"
      languages.each do |language|
        run language, version
      end

      return
    end

    if version == "all"
      versions_for(language).each do |version|
        execute definition_for(language), version
      end

      return
    end

    unless language == "base" || languages.includes? language
      abort "No definition for #{language}"
    end

    unless version.nil? || versions_for(language).includes? version
      abort "No definition for #{language} #{version}"
    end

    if language == "base"
      execute_base
    else
      execute definition_for(language), version
    end
  end

  def execute_base
    abort "This is not a base command."
  end

  def versions_for language
    definition_for(language).try(&.versions) || [] of String
  end

  def definition_for language
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
        SandboxDefinition.from_json File.read(path)
      rescue e
        abort "Failed to parse #{path}: #{e.message}."
      end
    }
  end

  def ensure_path_to definition
    Dir.mkdir_p path_to(definition)
  end

  def path_to definition, version=nil
    path = File.join Carcin::SANDBOX_BASEPATH, definition.name
    version ? File.join(path, version) : path
  end

  def base_path
    File.join Carcin::SANDBOX_BASEPATH, "bases", "base"
  end

  def base_path_for language
    File.join Carcin::SANDBOX_BASEPATH, "bases", language
  end

  def wrapper_path definition, version
    File.join path_to(definition), "sandboxed_#{definition.name}#{version}"
  end

  def whitelist_path definition, version
    File.join path_to(definition), "sandbox_whitelist#{version}"
  end

  def chrooted_system chroot, command
    system %(arch-chroot "#{chroot}" #{command})
  end
end

module BtrfsSubvolumeCommands
  def create_subvolume path
    system %(btrfs subvolume create "#{path}")
  end

  def create_snapshot of, path
    system %(btrfs subvolume snapshot "#{of}" "#{path}")
  end

  def delete_subvolume path
    system %(btrfs subvolume delete "#{path}")
  end
end

module BaseCommand
  def execute_base
    execute "base"
  end
end

module PackageBuilder
  PKG_BASEPATH = File.join Carcin::SANDBOX_BASEPATH, "pkgs"

  def build_package name, version=nil
    suffix = version ?  "-#{version}" : ""
    uid = File.stat(Carcin::SANDBOX_BASEPATH).uid
    as_user(uid) do
      Dir.mkdir_p PKG_BASEPATH
      Dir.chdir(PKG_BASEPATH) do
        File.rename "#{name}#{suffix}", name if File.exists? "#{name}#{suffix}"
        system "yaourt --noconfirm -G #{name}"
        File.rename name, "#{name}#{suffix}"
        Dir.chdir("#{name}#{suffix}") do
          replace_version version if version
          unless system("makepkg -s --noconfirm --pkg #{name}")
            abort "Failed to build #{name}#{suffix}"
          end
        end
      end
    end
  end

  def replace_version version
    File.write "PKGBUILD", File.read_lines("PKGBUILD").map {|line|
      line.gsub(/^pkgver=.+$/, "pkgver=#{version}")
          .gsub(/^_last_release=.+$/, "_last_release=#{version}")
    }.join
    system "updpkgsums"
  end

  def switch_user uid
    unless LibC.setuid(uid.to_i) == 0
      raise Errno.new "Can't switch to user #{uid}"
    end
  end

  def as_user uid
    pid = Process.fork do
      switch_user uid
      yield
      exit 0
    end

    Process.waitpid pid
  end

  def install_package sandbox, name, version=nil
    suffix = version ?  "-#{version}" : ""
    pkg = Dir["#{PKG_BASEPATH}/#{name}#{suffix}/#{name}-#{version}*.pkg.tar.xz"].first
    if pkg
      tmp_pkg = File.join sandbox, "tmp.pkg.tar.xz"
      system %(cp "#{pkg}" "#{tmp_pkg}")
      success = chrooted_system sandbox, "pacman --noconfirm -U /tmp.pkg.tar.xz"
      File.delete tmp_pkg
      abort "Failed to install #{pkg}" unless success
    else
      abort "No package built for #{name}#{suffix}"
    end
  end
end

class BuildBaseCommand
  include Command
  include BaseCommand
  include BtrfsSubvolumeCommands
  include PackageBuilder

  BASE_PACKAGES = %w(bash coreutils shadow file grep sed pacman)

  def execute definition, version=nil
    Dir.mkdir_p File.dirname(base_path)

    case definition
    when "base"
      build_base
    when SandboxDefinition
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
    chrooted_system base_path, "locale-gen"
  end

  def build definition
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

  def pacstrap path, packages
    system("pacstrap -cd #{path} #{packages.join(' ')}")
  end


  def create_user chroot, name
    chrooted_system chroot, "useradd -m #{name}"
  end
end

class DropBaseCommand
  include Command
  include BaseCommand
  include BtrfsSubvolumeCommands

  def execute definition, version=nil
    case definition
    when "base"
      drop base_path
    when SandboxDefinition
      drop base_path_for(definition.name)
    end
  end

  def drop path
    if File.exists? path
      delete_subvolume path
    else
      puts "#{path} does not exists, skip dropping."
    end
  end
end

class UpdateBaseCommand
  include Command
  include BaseCommand

  def execute definition, version=nil
    case definition
    when "base"
      update base_path
    when SandboxDefinition
      update base_path
      DropBaseCommand.new.execute definition
      BuildBaseCommand.new.execute definition
    end
  end

  def update path
    if File.exists? path
      chrooted_system path, "pacman -Syu --noconfirm"
    else
      abort "Can't update #{path}: no such directory."
    end
  end
end

class BuildCommand
  include Command
  include BtrfsSubvolumeCommands
  include PackageBuilder

  def execute definition, version
    path = path_to(definition, version)

    if File.exists? path
      puts "#{definition.name} #{version} exists, skipping."
      return
    end

    BuildBaseCommand.new.execute definition

    ensure_path_to definition
    build_package definition.name, version
    create_snapshot base_path_for(definition.name), path
    install_package path, definition.name, version

    BuildWrapperCommand.new.execute(definition, version)
    GenerateWhitelistCommand.new.execute(definition, version)
  end
end

class DropCommand
  include Command
  include BtrfsSubvolumeCommands

  def initialize(@confirm=true)
  end

  def execute definition, version
    path = path_to(definition, version)

    if File.exists? path
      delete_subvolume path
    else
      puts "#{path} does not exists, skip dropping."
    end
  end
end

class RebuildCommand
  include Command

  def execute definition, version
    DropCommand.new(false).execute definition, version
    BuildCommand.new.execute definition, version
  end
end

class BuildWrapperCommand
  class SandboxWrapper
    getter path
    getter name
    getter timeout
    getter memory
    getter whitelist
    ecr_file "#{__DIR__}/carcin/sandbox_wrapper.ecr"

    def initialize(@path, @name, @timeout, @memory, @whitelist)
    end
  end

  include Command

  def execute definition, version
    ensure_path_to definition

    wrapper = wrapper_path definition, version

    file = Tempfile.open("sandbox_wrapper") do |io|
      SandboxWrapper.new(
        path_to(definition, version),
        definition.name,
        definition.timeout,
        definition.memory,
        whitelist_path(definition, version)
      ).to_s(io)
    end

    unless system %(crystal build --release -o "#{wrapper}" "#{file.path}")
      abort "Failed to build #{wrapper}"
    end

    file.delete

    system %(chmod 4755 "#{wrapper}")
  end
end


class GenerateWhitelistCommand
  include Command

  ifdef x86_64
    ALL_SYSCALLS_LIST = "all_syscalls64"
  else
    ALL_SYSCALLS_LIST = "all_syscalls32"
  end

  def initialize(@force=false)
  end

  def execute definition, version
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

  def test_programs definition, version
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

Cli.new(ARGV).run({
  "build-base":         BuildBaseCommand.new,
  "drop-base":          DropBaseCommand.new,
  "update":             UpdateBaseCommand.new,
  "build":              BuildCommand.new,
  "drop":               DropCommand.new,
  "rebuild":            RebuildCommand.new,
  "build-wrapper":      BuildWrapperCommand.new,
  "generate-whitelist": GenerateWhitelistCommand.new(true)
})
