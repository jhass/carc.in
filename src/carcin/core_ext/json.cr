require "json"

def Object.from_json?(json, root=nil)
  if root
    object = JSON.parse(json)
    object = object[root]?
    json = object.to_json if object
  end
  from_json json
rescue e : JSON::ParseException
end

