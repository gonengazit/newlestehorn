local App = class("App")
local tools = require 'plugins.base.tools'

function App:init()
    local w, h = love.graphics.getDimensions()

    self.W, self.H = w, h
    self.camX, self.camY = 0, 0
    self.camScale = 2 -- calculated based on camScaleSetting
    self.camScaleSetting = 1 -- 0, 1, 2 is 1x, 2x, 3x etc, -1, -2, -3 is 0.5x, 0.25x, 0.125x
    self.room = nil -- room NUMBER
    
    self.tool = tools.Brush:new()
    self.currentTile = 0
    self.message = nil
    self.messageTimeLeft = nil
    self.playtesting = false
    self.showToolPanel = true
    self.showGarbageTiles = false
    self.showCameraTriggers = true

    -- history (undo stack)
    self.history = {}
    self.historyN = 0 -- index of current history item (can be less than #history to support redo)

    self.font = love.graphics.getFont()

    self.left, self.top = 0, 0 -- top left corner of editing area

    -- these are used in various hacks to work around nuklear being big dumb (or myself idk)
    self.anyWindowHovered = false
    self.enterPressed = false
    self.roomAdded = false
    self.suppressMouse = false -- disables mouse-driven editing in love.update() when a click has triggered a different action, reset on release
end

function App:toScreen(x, y)
    return (self.camX + x) * self.camScale + self.left,
           (self.camY + y) * self.camScale + self.top
end

function App:fromScreen(x, y)
    return (x - self.left)/self.camScale - self.camX,
           (y - self.top)/self.camScale - self.camY
end

function App:activeRoom()
    return app.room and project.rooms[app.room]
end

return App