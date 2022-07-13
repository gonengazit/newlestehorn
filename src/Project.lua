local Project = class("Project")

local util = require 'util'
local Room = require 'Room'



function Project:init()
    self.rooms = {}
    self.selection = nil
    self.selectedCamtriggerN = nil
    self.conf = {
        param_names = {},
        autotiles = {},
        composite_shapes = {},
    }
end

function Project:getState()
    local s = dumplualine(self)
    return s
end

function Project:setState(s)
    local p = loadlua(s)

    -- instantiate self with pairs from table
    for k, v in pairs(p) do
        self[k] = v
    end

    -- convert rooms into Room instances
    for n, room in pairs(self.rooms) do
        self.rooms[n] = util.instanceFromTable(Room, room)
    end
end



return Project