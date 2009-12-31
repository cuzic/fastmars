require 'rubygems'
require 'json'
require 'yaml'

filename = "lib/items.json"
siteinfos = JSON.parse(open(filename).read)

ary = siteinfos.map do |info|
  hash = info["data"]
  hash.delete "exampleUrl"
  hash
end


open("items.dump", "w") do |w|
  w.write ary.to_yaml
end
