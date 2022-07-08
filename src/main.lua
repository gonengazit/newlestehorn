nuklear = require 'nuklear'
filedialog = require 'filedialog'
serpent = require 'serpent'
class = require '30log'

local App = require 'plugins.base.App'
require 'util'
require 'room'
require 'autotiles'



-- global constants
psep = love.system.getOS() == "Windows" and "\\" or "/" -- path separator



function newProject()
    -- this is UI things
    love.graphics.setNewFont(12*global_scale)
    
    app = App:new()

    --ui:styleSetFont(love.graphics.getFont())
    ui:stylePush({['font']=app.font})
    --print(app.font:getHeight())

    -- this is what goes into history and (mostly) gets saved
    project = {
        rooms = {},
        selection = nil,
        selectedCamtriggerN = nil,
        conf = {
			param_names = {},
			autotiles = {},
			composite_shapes = {},
		},
    }

    -- basic p8data with blank spritesheet
    local data = {}
    local imgdata = love.image.newImageData(128, 64)
    imgdata:mapPixel(function() return 0, 0, 0, 1 end)
    data.spritesheet = love.graphics.newImage(imgdata)
    data.quads = {}
    for i = 0, 15 do
        for j = 0, 15 do
            data.quads[i + j*16] = love.graphics.newQuad(i*8, j*8, 8, 8, data.spritesheet:getDimensions())
        end
    end

    p8data = data
end

function placeSelection()
    if project.selection and app.room then
        local sel, room = project.selection, app:activeRoom()
        local i0, j0 = div8(sel.
        x - room.x), div8(sel.y - room.y)
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
    project.selection = nil
end

function select(i1, j1, i2, j2)
    local i0, j0, w, h = rectCont2Tiles(i1, j1, i2, j2)
    if w > 1 or h > 1 then
        local r = app:activeRoom()
        local selection = newRoom(r.x + i0*8, r.y + j0*8, w, h)
        for i = 0, w - 1 do
            for j = 0, h - 1 do
                selection.data[i][j] = r.data[i0 + i][j0 + j]
                r.data[i0 + i][j0 + j] = 0
            end
        end
        project.selection = selection
    end
end

function hoveredTriggerN()
    local room=app:activeRoom()
    if room then
        for n, trigger in ipairs(room.camtriggers) do
            local ti, tj = app:mouseOverTile()
            if ti and ti>=trigger.x and ti<trigger.x+trigger.w and tj>=trigger.y and tj<trigger.y+trigger.h then
                return n
            end
        end
    end
end

function selectedTrigger()
    return app:activeRoom() and app:activeRoom().camtriggers[app.selectedCamtriggerN]
end

function switchTool(toolClass)
    if app.tool and not app.tool:instanceOf(toolClass) then
        app.tool:disabled()
        app.tool = toolClass:new()
    end
end



require 'fileio'
require 'mainloop'
require 'mouse'