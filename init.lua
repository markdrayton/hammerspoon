mash = {"ctrl", "alt", "cmd"}

-- Logging
hs.logger.defaultLogLevel = "debug"
logger = hs.logger.new("main")

-- Local config variables
dofile("config.lua")

-- Spoons
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.use_syncinstall = true
Install = spoon.SpoonInstall

-- Better looking alerts
hs.alert.defaultStyle.radius = 10

-- Disable window size/location animations
hs.window.animationDuration = 0

-- Window layout
local laptop = "Color LCD"
local dell = "DELL U2713HM"

local layouts = {
  [1] = { -- one screen
    {"Google Chrome", nil, laptop, hs.layout.maximized, nil, nil},
    {"iTerm2", nil, laptop, hs.layout.maximized, nil, nil}
  },
  [2] = { -- two screens
    {"Google Chrome", nil, dell, hs.layout.left50, nil, nil},
    {"iTerm2", nil, dell, hs.layout.right50, nil, nil}
  }
}

screenWatcher = hs.screen.watcher.new(function()
  local screens = hs.screen.allScreens()
  logger.d("Found " .. #screens .. " screens")
  hs.layout.apply(layouts[#screens])
end)
screenWatcher:start()

-- Point DNS to home pihole
lastNetwork = hs.wifi.currentNetwork()

function setResolver(resolver)
  _, status = hs.execute("networksetup -setdnsservers Wi-Fi " .. resolver)
  if status == nil then
    logger.e("networksetup failed")
  end
end

function networkChanged()
  local newNetwork = hs.wifi.currentNetwork()
  if newNetwork == homeNetwork and lastNetwork ~= homeNetwork then
    logger.d("Pointing DNS resolver to " .. pihole)
    setResolver(pihole)
  elseif newNetwork ~= homeNetwork and lastNetwork == homeNetwork then
    logger.d("Clearing DNS resolvers")
    setResolver("Empty")
  end
  lastNetwork = newNetwork
end
wifiWatcher = hs.wifi.watcher.new(networkChanged)
wifiWatcher:start()

-- Automatically reload config
function reloadConfig(files)
  local doReload = false
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
  end
end
configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

hs.hotkey.bind(mash, "R", function() hs.reload() end)
hs.alert.show("Hammerspoon config loaded")
