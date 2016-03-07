module Carcin::Sandbox::BtrfsSubvolumeCommands
  def create_subvolume(path)
    system %(btrfs subvolume create "#{path}")
  end

  def create_snapshot(of, path)
    system %(btrfs subvolume snapshot "#{of}" "#{path}")
  end

  def delete_subvolume(path)
    system %(btrfs subvolume delete "#{path}")
  end
end
