require "tempfile"
require "ecr/macros"
require "./carcin"

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

{"btrfs", "pacstrap", "arch-chroot", "makepkg", "updpkgsums", "yaourt"}.each do |tool|
  unless has_command(tool)
    abort "This command needs the #{tool} tool."
  end
end

fs_type = `df -T #{Carcin::SANDBOX_BASEPATH}`.lines.last.split[1]
unless fs_type == "btrfs"
  abort "#{Carcin::SANDBOX_BASEPATH} must be on a btrfs filesystem."
end

def create_subvolume path
  Dir.mkdir_p File.dirname(path)
  system("btrfs subvolume create #{path}")
end

def create_snapshot of, path
  Dir.mkdir_p File.dirname(path)
  system("btrfs subvolume snapshot #{of} #{path}")
end

def pacstrap path, packages
  system("pacstrap -cd #{path} #{packages.join(' ')}")
end

def chrooted_system chroot, command
  system("arch-chroot #{chroot} #{command}")
end

def create_user chroot, name
  chrooted_system chroot, "useradd -m #{name}"
end

BASE_SANDBOX = File.join Carcin::SANDBOX_BASEPATH, "bases", "base"
BASE_PACKAGES = %w(bash coreutils shadow file grep sed pacman)

def ensure_base
  return if File.directory? BASE_SANDBOX

  create_subvolume BASE_SANDBOX
  pacstrap BASE_SANDBOX, BASE_PACKAGES
  File.open(File.join(BASE_SANDBOX, "etc/locale.gen"), "a") do |io|
    io.puts "\nen_US.UTF-8 UTF-8"
  end
  File.write File.join(BASE_SANDBOX, "etc/locale.conf"), "LANG=en_US.UTF-8"
  Dir.mkdir_p File.join(BASE_SANDBOX, "dev/shm")
  system "mknod -m666 #{File.join(BASE_SANDBOX, "dev/null")} c 1 3"
  chrooted_system BASE_SANDBOX, "locale-gen"
end

def switch_user uid
  raise Errno.new "Can't switch to user #{uid}" unless LibC.setuid(uid.to_i) == 0
end

def as_user uid
  pid = Process.fork do
    switch_user uid
    yield
    exit 0
  end

  Process.waitpid pid
end

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
        unless system("makepkg -s")
          abort "Failed to build #{name}#{suffix}"
        end
      end
    end
  end
end

def replace_version version
  File.write "PKGBUILD", File.read_lines("PKGBUILD").map {|line|
    line.gsub(/^version=.+$/, "version=#{version}")
        .gsub(/^_last_release=.+$/, "_last_release=#{version}")
  }.join
  system "updpkgsums"
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

def generate_wrapper sandbox, definition, version
  wrapper = File.expand_path File.join(sandbox, "../sandboxed_#{definition.name}#{version}")
  whitelist = File.expand_path File.join(sandbox, "../sandboxed_whitelist#{version}")
  file = Tempfile.open("sandbox_wrapper") do |io|
    SandboxWrapper.new(
      sandbox,
      definition.name,
      definition.timeout,
      definition.memory,
      whitelist
    ).to_s(io)
  end

  unless system %(crystal build --release -o "#{wrapper}" "#{file.path}")
    abort "Failed to build #{wrapper}"
  end

  file.delete

  system %(chmod 4755 "#{wrapper}")
end

ifdef x86_64
  ALL_SYSCALLS_LIST = "all_syscalls64"
else
  ALL_SYSCALLS_LIST = "all_syscalls32"
end

def generate_whitelist sandbox, definition, version
  whitelist = File.expand_path File.join(sandbox, "../sandboxed_whitelist#{version}")
  all_syscalls = File.read_lines File.join(Carcin::SANDBOX_BASEPATH, "definitions", ALL_SYSCALLS_LIST)
  needed_syscalls = all_syscalls.dup
  all_syscalls.each do |syscall|
    puts "Try without #{syscall}"
    File.write whitelist, (needed_syscalls - [syscall]).join
    if test_programs definition, version
      puts "Removing #{syscall}"
      needed_syscalls = needed_syscalls - [syscall]
    else
      puts "Keeping #{syscall}"
    end
  end
end

def test_programs definition, version
  definition.allowed_programs.each do |program|
    run = Carcin::Runner.execute Carcin::RunRequest.new(definition.name, version, program)
    puts "Exited with #{run.exit_code} for: #{program}"
    return false unless run.successful?
  end

  definition.allowed_failing_programs.each do |program|
    run = Carcin::Runner.execute Carcin::RunRequest.new(definition.name, version, program)
    puts "Exited with #{run.exit_code} for: #{program}"
    if run.stderr.starts_with?("playpen")
      return false if (run.signal && run.signal == 31) || run.stderr.includes?("timeout triggered!")
    elsif run.stderr.includes?("Bad system call")
      return false
    end
  end

  true
end

ensure_base

Dir["#{Carcin::SANDBOX_BASEPATH}/definitions/*.json"].each do |definition_path|
  definition = SandboxDefinition.from_json File.read(definition_path)
  base_path = File.join Carcin::SANDBOX_BASEPATH, "bases", definition.name
  path = File.join Carcin::SANDBOX_BASEPATH, definition.name

  unless File.exists? base_path
    create_snapshot BASE_SANDBOX, base_path
    pacstrap base_path, definition.dependencies
    definition.aur_dependencies.each do |name|
      build_package name
      install_package base_path, name
      create_user base_path, definition.name
    end
  end

  definition.versions.each do |version|
    sandbox = File.join path, version
    next if File.exists? sandbox
    build_package definition.name, version
    create_snapshot base_path, sandbox
    install_package sandbox, definition.name, version
    generate_wrapper sandbox, definition, version
    generate_whitelist sandbox, definition, version
  end
end
