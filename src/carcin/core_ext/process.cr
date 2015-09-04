lib LibC
  fun getuid() : Int32
  fun setuid(uid : Int32) : Int32
end

def Process.uid
  LibC.getuid
end

def Process.uid=(uid)
  unless LibC.setuid(uid.to_i32) == 0
    raise Errno.new "Can't switch to user #{uid}"
  end

  uid.to_i32
end
