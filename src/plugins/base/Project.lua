local Project = class("Project")



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
    -- this is an optimization that i decided to disable for now
    -- for n, room in pairs(self.rooms) do
    --     roomMakeStr(room)
    -- end
    -- roomMakeStr(self.selection)

    local s = serpent.line(self, {compact = true, comment = false, metatostring = false, keyignore = {data = true, class = true, super = true}})
    return s
end

function Project:setState(s)
    local p = loadlua(s)
    for k, v in pairs(p) do
        self[k] = v
    end

    -- for n, room in pairs(self.rooms) do
    --     roomMakeData(room)
    -- end
    -- roomMakeData(self.selection)
end



return Project