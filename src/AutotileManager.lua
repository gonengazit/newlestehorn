local AutotileManager = class("AutotileManager")



function AutotileManager:init(conf)
    self:update(conf)
end

function AutotileManager:update(conf)
    self.autotiles = (conf or {}).autotiles or {}

    -- calculate auxillary tables for autotile manipulation
    self.matchTable, self.matchTableStrict = {}, {}
    -- n => set of autotiles n belongs to
    -- strict excludes extra autotiles (>=16)

    for n = 0, 255 do
        self.matchTable[n] = {}
        self.matchTableStrict[n] = {}
    end

    for k, auto in pairs(self.autotiles) do
        for o, n in pairs(auto) do
            self.matchTable[n][k] = true
            if o >= 0 and o < 16 then
                self.matchTableStrict[n][k] = true
            end
        end
    end
end

-- out of bounds matcher (matches all tiles)
local oob = {}
for n = 0, 255 do
    oob[n] = true
end

function AutotileManager:getMatcher(room, i, j, strict)
    if i >= 0 and i < room.w and j >= 0 and j < room.h then
        local t = strict and self.matchTableStrict or self.matchTable
        return t[room.data[i][j]]
    else
        return oob
    end
end

local function b1(b) -- converts truthy to 1, falsy to 0
    return b and 1 or 0
end

function AutotileManager:tile(room, i, j, k)
    local match = self:getMatcher(room, i, j, true)
    if k and match ~= oob and match[k] then
        local nb = b1(self:getMatcher(room, i + 1, j)[k])
                 + b1(self:getMatcher(room, i - 1, j)[k]) * 2
                 + b1(self:getMatcher(room, i, j + 1)[k]) * 4
                 + b1(self:getMatcher(room, i, j - 1)[k]) * 8
        room.data[i][j] = self.autotiles[k][nb]
    end
end

function AutotileManager:tileWithNeighbors(room, i, j, k)
    self:tile(room, i, j, k)
    self:tile(room, i + 1, j, k)
    self:tile(room, i - 1, j, k)
    self:tile(room, i, j + 1, k)
    self:tile(room, i, j - 1, k)
end



return AutotileManager