require "json"

module Carcin::Sandbox
  class Definition
    JSON.mapping({
      name:                     String,
      versions:                 Array(String),
      split_packages:           {type: Array(String), nilable: true},
      binary:                   {type: String, nilable: true},
      dependencies:             Array(String),
      aur_dependencies:         Array(String),
      timeout:                  Int32,
      memory:                   {type: Int32, nilable: true},
      max_tasks:                Int32,
      allowed_programs:         Array(String)
      }, true)
  end
end
