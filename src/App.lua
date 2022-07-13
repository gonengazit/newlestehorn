local Project = require 'Project'
local Room = require 'Room'
local tools = require 'plugins.base.tools'

local App = class("App")



function App:init()
    local w, h = love.graphics.getDimensions()

    -- this is what goes into history and (mostly) gets saved
    self.project = Project:new()

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
    self.upscale = 16

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

function App:getMouse()
    local x, y = love.mouse.getPosition()
    local mx, my = self:fromScreen(x, y)

    return mx, my
end

function App:activeRoom()
    return self.room and self.project.rooms[self.room]
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
            local x, y = self:activeRoom().x + ti*8, self:activeRoom().y + tj*8
            love.graphics.draw(p8data.spritesheet, p8data.quads[tile], x, y, 0, 1/app.upscale)
            self:drawCompositeShape(tile, x, y)
        end

        love.graphics.setColor(col)
        love.graphics.setLineWidth(1 / self.camScale)
        love.graphics.rectangle("line", self:activeRoom().x + ti*8 + 0.5 / self.camScale,
                                        self:activeRoom().y + tj*8 + 0.5 / self.camScale, 8, 8)
    end
end



function App:getCompositeShape(n)
    -- get composite shape that n should draw, and the offset
    -- returns shape,dx,dy
    for _, shape in ipairs(self.project.conf.composite_shapes) do
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
                local m = math.abs(shape[oy][ox]) --negative sprite is drawn, but not used as a source for the shape
                if m~= 0 then
                    love.graphics.draw(p8data.spritesheet_noblack, p8data.quads[m], x + (ox-dx)*8, y + (oy-dy)*8, 0, 1/app.upscale)
                end
            end
        end
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

function App:showMessage(msg)
    self.message = msg
    self.messageTimeLeft = 4
end

function App:pushHistory()
    local s = self.project:getState()

    if s ~= self.history[self.historyN] then
        self.historyN = self.historyN + 1

        for i = self.historyN, #self.history do
            self.history[i] = nil
        end

        self.history[self.historyN] = s
    end
end

function App:undo()
    if self.historyN >= 2 then
        self.historyN = self.historyN - 1

        self.project:setState(self.history[self.historyN])
    end

    if not self:activeRoom() then self.room = nil end
end

function App:redo()
    if self.historyN <= #self.history - 1 then
        self.historyN = self.historyN + 1

        self.project:setState(self.history[self.historyN])
    end

    if not self:activeRoom() then self.room = nil end
end

function App:select(i1, j1, i2, j2)
    local i0, j0, w, h = rectCont2Tiles(i1, j1, i2, j2)
    if w > 1 or h > 1 then
        local r = self:activeRoom()
        local selection = Room:new(r.x + i0*8, r.y + j0*8, w, h)
        for i = 0, w - 1 do
            for j = 0, h - 1 do
                selection.data[i][j] = r.data[i0 + i][j0 + j]
                r.data[i0 + i][j0 + j] = 0
            end
        end
        self.project.selection = selection
    end
end

function App:placeSelection()
    if self.project.selection and self:activeRoom() then
        local sel, room = self.project.selection, self:activeRoom()
        local i0, j0 = div8(sel.x - room.x), div8(sel.y - room.y)
        for i = 0, sel.w - 1 do
            if i0 + i >= 0 and i0 + i < room.w then
                for j = 0, sel.h - 1 do
                    if j0 + j >= 0 and j0 + j < room.h then
                        room.data[i0 + i][j0 + j] = sel.data[i][j]
                    end
                end
            end
        end
    end
    self.project.selection = nil
end

function App:hoveredTriggerN()
    local room=app:activeRoom()
    if room then
        for n, trigger in ipairs(room.camtriggers) do
            local ti, tj = self:mouseOverTile()
            if ti and ti>=trigger.x and ti<trigger.x+trigger.w and tj>=trigger.y and tj<trigger.y+trigger.h then
                return n
            end
        end
    end
end

function App:selectedTrigger()
    return self:activeRoom() and self:activeRoom().camtriggers[self.selectedCamtriggerN]
end

function App:switchTool(toolClass)
    if self.tool and not self.tool:instanceOf(toolClass) then
        self.tool:disabled()
        self.tool = toolClass:new()
    end
end

return App