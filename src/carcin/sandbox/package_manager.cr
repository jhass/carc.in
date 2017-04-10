require "../core_ext/process"

module Carcin::Sandbox::PackageManager
  PKG_BASEPATH = File.join Carcin::SANDBOX_BASEPATH, "pkgs"

  def ensure_package_exists(sandbox, name, version=nil, extra_names=nil)
    packages = package_paths(sandbox, name, version, extra_names)

    if packages.empty?
      abort "No package exists for #{name} #{version}"
    end

    packages.group_by(&.first).each do |name, group|
      if group.size > 1
        abort "Multiple packages for #{name} #{version}, please delete all but the one you want to use"
      end
    end
  end

  def install_package(sandbox, name, version=nil, extra_names=nil)
    packages = package_paths(sandbox, name, version, extra_names)

    if packages.empty?
      abort "No package exists for #{name} #{version}"
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
      abort "Failed to install #{packages.map(&.first).join(", ")}"
    end
  end

  private def package_paths(sandbox, name, version=nil, extra_names=nil)
    extra_names ||= [] of String
    package_names = [name].concat extra_names
    pattern = File.join(PKG_BASEPATH, "#{name}", "{#{package_names.join(",")}}-#{version}*.pkg.tar.xz")
    packages = Dir[pattern].map {|path|
      name = File.basename(path)
      {name, path, File.join(sandbox, name)}
    }
  end
end
