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

-- Open console
hs.hotkey.bind(mash, "Y", nil, hs.toggleConsole)

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

applyLayout = function()
  local screens = hs.screen.allScreens()
  logger.d("Found " .. #screens .. " screens")
  hs.layout.apply(layouts[#screens])
end

screenWatcher = hs.screen.watcher.new(applyLayout)
screenWatcher:start()
hs.hotkey.bind(mash, "L", nil, applyLayout)

-- Chrome history
hs.hotkey.bind(mash, "C", nil, function()
  local iterm = hs.application.get("iTerm2")
  local originalWindows = {}
  if iterm then
    originalWindows = iterm:visibleWindows()
  end
  -- make a new window if iTerm isn't running or has no windows
  hs.application.launchOrFocus("/Applications/iTerm.app/Contents/MacOS/iTerm2")
  hs.timer.waitUntil(
    function()
      return hs.window.focusedWindow():application():name() == "iTerm2"
    end,
    function()
      if #originalWindows > 0 then
        -- already had some windows open so make a new one
        hs.eventtap.keyStroke({"cmd"}, "N")
      end
      -- leave time to open the window
      hs.timer.doAfter(0.05, function()
        local win = hs.window:focusedWindow()
        if win:screen():name() == dell then
          win:move({0.15, 0.15, 0.7, 0.7})
        else
          win:maximize()
        end
        hs.eventtap.keyStrokes("unset HISTFILE; ch; exit\n")
      end)
    end,
    0.05
  )
end)

local wm = hs.webview.windowMasks
Install:andUse("DeepLTranslate", {
  disable = false,
  config = {
    popup_style = wm.utility|wm.HUD|wm.titled|wm.closable|wm.resizable,
  },
  hotkeys = {
    translate = { mash, "E" },
  }
})

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
