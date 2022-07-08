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
    return self.room and project.rooms[self.room]
end


function App:mouseOverTile()
    if self:activeRoom() then
        local x, y = love.mouse.getPosition()
        local mx, my = self:fromScreen(x, y)
        local ti, tj = div8(mx - self:activeRoom().x), div8(my - self:activeRoom().y)
        if ti >= 0 and ti < self:activeRoom().w and tj >= 0 and tj < self:activeRoom().h then
            return ti, tj
        end
    end
end

function App:drawMouseOverTile(col, tile)
    local col = col or {0, 1, 0.5}

    local ti, tj = self:mouseOverTile()
    if ti then
        love.graphics.setColor(1, 1, 1)
        if tile then
            local x, y=self:activeRoom().x + ti*8, self:activeRoom().y + tj*8
            love.graphics.draw(p8data.spritesheet, p8data.quads[tile], x,y)
            self:drawCompositeShape(tile, x, y)
        end

        love.graphics.setColor(col)
        love.graphics.setLineWidth(1 / self.camScale)
        love.graphics.rectangle("line", self:activeRoom().x + ti*8 + 0.5 / self.camScale,
                                        self:activeRoom().y + tj*8 + 0.5 / self.camScale, 8, 8)
    end
end

function App:drawColoredRect(room, x, y, w, h, col, filled)
    love.graphics.setColor(col)
    love.graphics.setLineWidth(1 / self.camScale)
    love.graphics.rectangle("line", room.x + x + 0.5 / self.camScale,
                                    room.y + y + 0.5 / self.camScale,
                                    w, h)
    if filled then
        love.graphics.setColor(col[1], col[2], col[3], 0.25)
        love.graphics.rectangle("fill", room.x + x + 0.5 / self.camScale,
                                        room.y + y + 0.5 / self.camScale,
                                        w, h)
    end
end

function App:getCompositeShape(n)
    -- get composite shape that n should draw, and the offset
    -- returns shape,dx,dy
    for _, shape in ipairs(project.conf.composite_shapes) do
        for oy=1,#shape do
            for ox=1,#shape[oy] do
                if shape[oy][ox]==n then
                    return shape,ox,oy
                end
            end
        end
    end
end

function App:drawCompositeShape(n, x, y)
    if not p8data.quads[n] then print(n) end
    local shape, dx, dy = self:getCompositeShape(n)
    love.graphics.setColor(1, 1, 1, 0.5)
    if shape then
        for oy=1,#shape do
            for ox=1,#shape[oy] do
                local m=math.abs(shape[oy][ox]) --negative sprite is drawn, but not used as a source for the shape
                if m~= 0 then
                    love.graphics.draw(p8data.spritesheet_noblack, p8data.quads[m], x + (ox-dx)*8, y + (oy-dy)*8)
                end
            end
        end
    end
end

function App:showMessage(msg)
    self.message = msg
    self.messageTimeLeft = 4
end

return App