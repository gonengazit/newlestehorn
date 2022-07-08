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

function switchTool(toolClass)
    if app.tool and not app.tool:instanceOf(toolClass) then
        app.tool:disabled()
        app.tool = toolClass:new()
    end
end



require 'fileio'
require 'mainloop'
require 'mouse'