mash = {"ctrl", "alt", "cmd"}

-- Logging
hs.logger.defaultLogLevel = "debug"
logger = hs.logger.new("main")

-- I can never remember how to print a table
function walk(table)
  for k, v in pairs(table) do
    print(k, v)
  end
end

-- Local config variables
function localconfig()
  local f, err = loadfile("config.lua")
  if err then
    print("-- No config.lua found.")
  else
    f()
  end
end
localconfig()

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

function video(app, match)
  local r = {}
  if app then
    local comp = function(title)
      -- not not to cast to bool
      return not not (
        string.match(title, "%f[%a]YouTube%f[%A]")
        or string.match(title, "%f[%a]ITV Hub%f[%A]")
      )
    end
    local wins = hs.application.get(app):visibleWindows()
    for _, w in ipairs(wins) do
      if comp(w:title()) == match then
        r[#r + 1] = w
      end
    end
  end
  return r
end

function is_video(app)
  return video(app, true)
end

function is_not_video(app)
  return video(app, false)
end

local layouts = {
  [1] = { -- one screen
    {"Google Chrome", nil, laptop, hs.layout.maximized, nil, nil},
    {"Firefox", nil, laptop, hs.layout.maximized, nil, nil},
    {"iTerm2", nil, laptop, hs.layout.maximized, nil, nil},
    {"Slack", nil, laptop, hs.layout.maximized, nil, nil},
    {"zoom.us", "Zoom Meeting", laptop, hs.layout.maximized, nil, nil},
  },
  [2] = { -- two screens
    {"Google Chrome", is_not_video, dell, hs.layout.left50, nil, nil},
    {"Firefox", is_not_video, dell, hs.layout.left50, nil, nil},
    {"iTerm2", nil, dell, hs.layout.right50, nil, nil},
    {"Google Chrome", is_video, laptop, hs.layout.maximized, nil, nil},
    {"Firefox", is_video, laptop, hs.layout.maximized, nil, nil},
    {"Signal", nil, laptop, hs.geometry.rect(0.2, 0.15, 0.6, 0.7), nil, nil},
    {"Music", nil, laptop, hs.layout.maximized, nil, nil},
    {"Slack", nil, laptop, hs.layout.maximized, nil, nil},
    {"zoom.us", "Zoom Meeting", laptop, hs.layout.maximized, nil, nil},
  }
}

hs.hotkey.bind(mash, "L", nil, function()
  local screens = hs.screen.allScreens()
  hs.layout.apply(layouts[#screens])
end)

-- Browser history
hs.hotkey.bind(mash, "H", nil, function()
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
        hs.eventtap.keyStrokes(" unset HISTFILE\n")
        hs.eventtap.keyStrokes("echo -ne \"\\033]0;\"Browser history\"\\007\"; fh; exit\n")
      end)
    end,
    0.05
  )
end)

-- DeepL translate
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

-- Toggle caffeine
Install:andUse("Caffeine", {
  start = true,
  hotkeys = {
    toggle = { mash, "C" }
  }
})

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
