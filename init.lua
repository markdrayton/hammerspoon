local secrets = require("secrets")
secrets.start("secrets.json")

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
local laptop = "Built-in Retina Display"
local dell = "DELL U2713HM"

local split = 0.5

function video(app, match)
  local r = {}
  if app then
    local comp = function(title)
      -- not not to cast to bool
      return not not (
        -- %f[%a]: not letter followed by letter frontier pattern
        -- %f[%A]: letter followed by not letter frontier pattern
        string.match(title, "%f[%a]YouTube%f[%A]")
        or string.match(title, "%f[%a]ITV Hub%f[%A]")
        or string.match(title, "%f[%a]Nest%f[%A]")
        or string.match(title, "%f[%a]Meet%f[%A]")
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

function split_left()
  return hs.geometry.rect(0, 0, split, 1)
end

function split_right()
  return hs.geometry.rect(split, 0, 1 - split, 1)
end

local layouts = {
  [1] = { -- one screen
    {"Google Chrome", nil, laptop, hs.layout.maximized, nil, nil},
    {"Firefox", nil, laptop, hs.layout.maximized, nil, nil},
    {"Safari", nil, laptop, hs.layout.maximized, nil, nil},
    {"Code", nil, laptop, hs.layout.maximized, nil, nil},
    {"iTerm2", nil, laptop, hs.layout.maximized, nil, nil},
    {"Slack", nil, laptop, hs.layout.maximized, nil, nil},
    {"zoom.us", "Zoom Meeting", laptop, hs.layout.maximized, nil, nil},
  },
  [2] = { -- two screens
    {"Google Chrome", is_not_video, dell, split_left, nil, nil},
    {"Firefox", is_not_video, dell, split_left, nil, nil},
    {"Safari", is_not_video, dell, split_left, nil, nil},
    {"Code", nil, dell, split_left, nil, nil},
    {"Google Chrome", is_video, laptop, hs.layout.maximized, nil, nil},
    {"Firefox", is_video, laptop, hs.layout.maximized, nil, nil},
    {"Safari", is_video, laptop, hs.layout.maximized, nil, nil},
    {"iTerm2", nil, dell, split_right, nil, nil},
    {"Signal", nil, laptop, hs.geometry.rect(0.2, 0.15, 0.6, 0.7), nil, nil},
    {"Music", nil, laptop, hs.layout.maximized, nil, nil},
    {"Slack", nil, laptop, hs.layout.maximized, nil, nil},
    {"zoom.us", "Zoom Meeting", laptop, hs.layout.maximized, nil, nil},
  }
}

function apply_layout()
  local screens = hs.screen.allScreens()
  hs.layout.apply(layouts[#screens])
end

hs.hotkey.bind(mash, "J", nil, function()
  split = math.max(0, split - 0.05)
  apply_layout()
end)

hs.hotkey.bind(mash, "K", nil, function()
  split = math.min(1, split + 0.05)
  apply_layout()
end)

hs.hotkey.bind(mash, "L", nil, function()
  split = 0.5
  apply_layout()
end)

hs.hotkey.bind(mash, "Z", nil, function()
  local layout = {
    {"TrainerRoad", nil, laptop, nil, hs.geometry.rect{0, 25, 960, 640}, nil},
    {"ZwiftApp", nil, laptop, hs.geometry.rect{0.5, 0.5, 0.5, 0.5}, nil, nil},
  }
  for _, app in ipairs(hs.application.runningApplications()) do
    local match = hs.fnutils.find(layout, function(win) return win[1] == app:name() end)
    if match == nil then
      app:hide()
    end
  end
  hs.layout.apply(layout)
  hs.application.find("TrainerRoad"):setFrontmost()
end)

-- Window movement
function set_frame(func)
  local win = hs.window.focusedWindow()
  local frame = win:frame()
  local max = win:screen():frame()

  func(frame, max)
  win:setFrame(frame)
end

hs.hotkey.bind(mash, "M", function()
  set_frame(function(f, m) f.x = m.x; f.y = m.y; f.w = m.w; f.h = m.h end)
end)

hs.hotkey.bind(mash, "Left", function()
  set_frame(function(f, m) f.x = m.x; f.y = m.y; f.w = m.w / 2; f.h = m.h end)
end)

hs.hotkey.bind(mash, "Right", function()
  set_frame(function(f, m) f.x = m.x + (m.w / 2); f.y = m.y; f.w = m.w / 2; f.h = m.h end)
end)

hs.hotkey.bind(mash, "Up", function()
  set_frame(function(f, m) f.y = m.y; f.h = m.h / 2 end)
end)

hs.hotkey.bind(mash, "Down", function()
  set_frame(function(f, m) f.y = m.y + (m.h / 2) end)
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
        local win = hs.window.focusedWindow()
        if win:screen():name() == dell then
          win:move({0.15, 0.15, 0.7, 0.7})
        else
          win:maximize()
        end
        hs.eventtap.keyStrokes(" unset HISTFILE\n")
        hs.eventtap.keyStrokes("echo -ne \"\\033]0;\"Browser history\"\\007\"; browser-history; exit\n")
      end)
    end,
    0.05
  )
end)

-- Portuguese lessons
hs.hotkey.bind(mash, "P", nil, function()
  local pt_url = hs.settings.get("secrets").pt_url
  if pt_url then
    hs.urlevent.openURLWithBundle(pt_url, "us.zoom.xos")
  else
    print("No URL configured for Portuguese lessons.")
  end
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

-- Mute when displays sleep
local originalMuted = true
function caffeinateCallback(eventType)
  local device = hs.audiodevice.defaultOutputDevice()
  if device then
    if (eventType == hs.caffeinate.watcher.screensDidSleep) then
      originalMuted = device:muted()
      device:setMuted(true)
      print("Screen sleeping, muted audio (previous mute state was " .. tostring(originalMuted) .. ")")
    elseif (eventType == hs.caffeinate.watcher.screensDidWake) then
      device:setMuted(originalMuted)
      print("Screen awake, restored mute state to " .. tostring(originalMuted))
    end
  end
end
caffeinateWatcher = hs.caffeinate.watcher.new(caffeinateCallback):start()

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
