require "./carcin"
require "./carcin/sandbox/*"

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

Carcin::Sandbox::Cli.new(ARGV).run({
  "build-base":         Carcin::Sandbox::BuildBaseCommand.new,
  "drop-base":          Carcin::Sandbox::DropBaseCommand.new,
  "update":             Carcin::Sandbox::UpdateBaseCommand.new,
  "build":              Carcin::Sandbox::BuildCommand.new,
  "drop":               Carcin::Sandbox::DropCommand.new,
  "rebuild":            Carcin::Sandbox::RebuildCommand.new,
  "build-wrapper":      Carcin::Sandbox::BuildWrapperCommand.new,
  "generate-whitelist": Carcin::Sandbox::GenerateWhitelistCommand.new(true)
})
