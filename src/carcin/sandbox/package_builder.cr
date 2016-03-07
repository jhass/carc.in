require "../core_ext/process"

module Carcin::Sandbox::PackageBuilder
  PKG_BASEPATH = File.join Carcin::SANDBOX_BASEPATH, "pkgs"

  def build_package(name, version=nil, extra_names=nil)
    suffix = version ?  "-#{version}" : ""
    extra_names ||= [] of String
    uid = File.stat(Carcin::SANDBOX_BASEPATH).uid
    as_user(uid) do
      Dir.mkdir_p PKG_BASEPATH
      Dir.cd(PKG_BASEPATH) do
        File.rename "#{name}#{suffix}", name if File.exists? "#{name}#{suffix}"
        system "yaourt --noconfirm -G #{name}"
        File.rename name, "#{name}#{suffix}"
        Dir.cd("#{name}#{suffix}") do
          replace_version version if version
          packages = [name].concat extra_names
          unless system("makepkg -s --noconfirm --nocheck")
            abort "Failed to build #{name}#{suffix}"
          end
        end
      end
    end
  end

  def replace_version(version)
    File.write "PKGBUILD", File.read_lines("PKGBUILD").map {|line|
      line.gsub(/^pkgver=.+$/, "pkgver=#{version}")
          .gsub(/^_last_release=.+$/, "_last_release=#{version}")
    }.join
    system "updpkgsums"
  end

  def as_user(uid)
    process = Process.fork do
      Process.uid = uid
      yield
      exit 0
    end

    process.wait
  end

  def install_packages(sandbox, name, version=nil, extra_names=nil)
    packages.each do |package|
      install_package sandbox, package, version
    end
  end

  def install_package(sandbox, name, version=nil, extra_names=nil)
    suffix = version ?  "-#{version}" : ""
    extra_names ||= [] of String
    package_names = [name].concat extra_names
    pattern = File.join(PKG_BASEPATH, "#{name}#{suffix}", "{#{package_names.join(",")}}-#{version}*.pkg.tar.xz")
    packages = Dir[pattern].map {|path|
      name = File.basename(path)
      [name, path, File.join(sandbox, name)]
    }

    if packages.empty?
      abort "No package built for #{name}#{suffix}"
    end

    packages.each do |package|
      name, path, target = package
      system %(cp "#{path}" "#{target}")
    end

    success = chrooted_system sandbox, "pacman --noconfirm -U #{packages.map {|package| "/#{package.first}" }.join(" ")}"

    packages.each do |package|
      name, path, target = package
      File.delete target
    end

    unless success
      abort "Failed to install #{package_names.join(", ")}"
    end
  end
end
