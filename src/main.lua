nuklear = require 'nuklear'
filedialog = require 'filedialog'
serpent = require 'lib.serpent'
class = require 'lib.30log'

local App = require 'plugins.base.App'
local util = require 'util'
require 'room'
require 'autotiles'



-- global constants
psep = love.system.getOS() == "Windows" and "\\" or "/" -- path separator



function newProject()
    -- this is UI things
    app = App:new()

    -- basic p8data with blank spritesheet
    local data = {}
    local imgdata = love.image.newImageData(128, 128)
    imgdata:mapPixel(function() return 0, 0, 0, 1 end)
    data.spritesheet = love.graphics.newImage(util.upscale(imgdata, app.upscale))
    data.quads = {}
    for i = 0, 15 do
        for j = 0, 15 do
            data.quads[i + j*16] = love.graphics.newQuad(i*8*app.upscale, j*8*app.upscale, 8*app.upscale, 8*app.upscale, data.spritesheet)
        end
    end

    p8data = data
end


require 'fileio'
require 'mainloop'
require 'mouse'