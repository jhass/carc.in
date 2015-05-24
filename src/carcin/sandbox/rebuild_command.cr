require "./command"
require "./drop_command"
require "./build_command"

class Carcin::Sandbox::RebuildCommand
  include Command

  def execute definition, version
    DropCommand.new(false).execute definition, version
    BuildCommand.new.execute definition, version
  end
end
