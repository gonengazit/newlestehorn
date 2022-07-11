local Room = class("Room")

local util = require 'util'
local tools = require 'plugins.base.tools'



function Room:init(x, y, w, h)
    self.x = x or 0
    self.y = y or 0
    self.w = w or 16
    self.h = h or 16
    self.hex = true
    self.data = fill2d0s(self.w, self.h)
    self.exits = {left = false, bottom = false, right = false, top = true}
    self.params = {}
    self.title = ""
    self.camtriggers = {} 
end

function Room:draw(p8data, highlight)
    --background color
    love.graphics.setColor(0.133, 0.133, 0.133)
    love.graphics.rectangle("fill", self.x, self.y, self.w*8, self.h*8)
    
    love.graphics.setColor(1, 1, 1)
    
    -- draw shapes bigger than 1x1 (like spinners)
    for i = 0, self.w - 1 do
        for j = 0, self.h - 1 do
            local n = self.data[i][j]
            app:drawCompositeShape(n,self.x+8*i,self.y+8*j)
        end
    end
    
    -- tiles
    for i = 0, self.w - 1 do
        for j = 0, self.h - 1 do
            local n = self.data[i][j]
            if not p8data.quads[n] then print(n) end
            if not highlight or n~=0 then
                love.graphics.setColor(1, 1, 1)

                if n~= 0 then
                    love.graphics.draw(p8data.spritesheet, p8data.quads[n], self.x + i*8, self.y + j*8, 0, 1/app.upscale)
                end
            end
        end
    end

    if highlight then
        app:drawColoredRect(self, 0, 0, self.w*8, self.h*8, {0, 1, 0.5}, true)
    end

    if app.tool:instanceOf(tools.Camtrigger) or app.showCameraTriggers then
        local highlighted = app.tool:instanceOf(tools.Camtrigger) and (app.selectedCamtriggerN or app:hoveredTriggerN())
        for n, trigger in ipairs(self.camtriggers) do
            local col
            if self == app:activeRoom() and n == highlighted then
                if app.selectedCamtriggerN then
                    col = {0.5,1,0}
                else
                    col = {1,0.9,0}
                end
            else
                col = {1,0.75,0}
            end

            app:drawColoredRect(self, trigger.x*8, trigger.y*8, trigger.w*8, trigger.h*8, col, true)
        end
    end
end



return Room