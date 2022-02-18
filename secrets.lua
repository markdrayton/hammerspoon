module = {}

module.start = function(filename)
  if hs.fs.attributes(filename) then
    hs.settings.set("secrets", hs.json.read(filename))
  else
    print("Missing secrets file: " .. filename)
  end
end

return module
