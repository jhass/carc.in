class Carcin::Sandbox::Cli
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
      "build":              "all",
      "drop":               "all",
      "rebuild":            "all",
      "build-wrapper":      "all",
      "generate-whitelist": "all"
    }
  }

  def initialize(arguments)
    help if (arguments & %w(help -h --help)).any? || arguments.empty?

    @command  = arguments[0]
    @language = arguments[1]? || ARGUMENT_DEFAULTS[:language].fetch(@command) { help "No target given" }
    @version  = arguments[2]? || ARGUMENT_DEFAULTS[:version].fetch(@command) { help "No version given" }
  end

  def run(commands)
    command = commands.fetch(@command) { help "Command not found" }
    command.run(@language, @version)
  end

  def help(reason=nil)
    puts "#{reason}\n\n" if reason
    puts "Build and manage sandboxes"
    puts
    puts "  help, -h, --help                                         Display this."
    puts "  build-base         <language>|[base]                     Build base chroot."
    puts "  drop-base          <language>|[base]                     Drop base chroot."
    puts "  update             <language>|all|[base]                 Update base chroot and rebuild (all) sandbox bases."
    puts "  build              <language>|all        <version>|[all] Build (all) sandboxes."
    puts "  drop               <language>|all        <version>|[all] Drop (all) sandboxes."
    puts "  rebuild            <language>|all        <version>|[all] Rebuild (all) sandboxes."
    puts "  build-wrapper      <language>|all        <version>|[all] (Re)build (all) playpen wrappers."
    puts "  generate-whitelist <language>|all        <version>|[all] Generate new syscall whitelist."
    puts
    exit 0
  end
end
