local keyboard = require "plugins.base.keyboard"

local shortcuts = {}

shortcuts.Open = keyboard.Shortcut:extend("Open", {mod = {"ctrl"}, key = "o"})
function shortcuts.Open:run()
    openFile()
end

return shortcuts