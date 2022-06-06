--  8
--2 O 1
--  4

function updateAutotiles()
    -- calculates auxillary tables for autotile manipulation

    project.autotilet, project.autotilet_strict = {}, {}
    -- n => set of autotiles n belongs to
    -- strict excludes extra autotiles (>=16)

    for n = 0, 255 do
        project.autotilet[n] = {}
        project.autotilet_strict[n] = {}
    end

    for k, auto in pairs(project.conf.autotiles) do
        for o, n in pairs(auto) do
            project.autotilet[n][k] = true
            if o >= 0 and o < 16 then
                project.autotilet_strict[n][k] = true
            end
        end
    end
end

function defaultAutotiles()
    local autotiles = {
        -- snow
        [1] = {
            [0]  = 32,
            [1]  = 52,
            [2]  = 54,
            [3]  = 53,
            [4]  = 39,
            [5]  = 33,
            [6]  = 35,
            [7]  = 34,
            [8]  = 55,
            [9]  = 49,
            [10] = 51,
            [11] = 50,
            [12] = 48,
            [13] = 36,
            [14] = 38,
            [15] = 37,
            -- indexes beyond 15 can be used to allow connecting to extra tiles
            [16] = 72,
        },
        -- ice
        [2] = {
            [0]  = 117,
            [1]  = 114,
            [2]  = 116,
            [3]  = 115,
            [4]  = 69,
            [5]  = 66,
            [6]  = 68,
            [7]  = 67,
            [8]  = 101,
            [9]  = 98,
            [10] = 100,
            [11] = 99,
            [12] = 85,
            [13] = 82,
            [14] = 84,
            [15] = 83,
        },
        -- bg dirt (simplistic - only corner tiles are used)
        [3] = {
            [0]  = 40,
            [1]  = 40,
            [2]  = 40,
            [3]  = 40,
            [4]  = 40,
            [5]  = 58,
            [6]  = 57,
            [7]  = 40,
            [8]  = 40,
            [9]  = 42,
            [10] = 41,
            [11] = 40,
            [12] = 40,
            [13] = 40,
            [14] = 40,
            [15] = 40,
            -- extra
            [16] = 16,
            [17] = 56,
            [18] = 88,
            [19] = 103,
            [20] = 104,
        },
    }

    return autotiles
end

-- out of bounds matched all tilesets
local oob = {}
for n = 0, 255 do
    oob[n] = true
end

local function matchAutotile(room, i, j, strict)
    if i >= 0 and i < room.w and j >= 0 and j < room.h then
        local t = strict and project.autotilet_strict or project.autotilet
        return t[room.data[i][j]]
    else
        return oob
    end
end

local function b1(b) -- converts truthy to 1, falsy to 0
    return b and 1 or 0
end

function autotile(room, i, j, k)
    local match = matchAutotile(room, i, j, true)
    if k and match ~= oob and match[k] then
        local nb = b1(matchAutotile(room, i + 1, j)[k])
                 + b1(matchAutotile(room, i - 1, j)[k]) * 2
                 + b1(matchAutotile(room, i, j + 1)[k]) * 4
                 + b1(matchAutotile(room, i, j - 1)[k]) * 8
        room.data[i][j] = project.conf.autotiles[k][nb]
    end
end

function autotileWithNeighbors(room, i, j, k)
    autotile(room, i, j, k)
    autotile(room, i + 1, j, k)
    autotile(room, i - 1, j, k)
    autotile(room, i, j + 1, k)
    autotile(room, i, j - 1, k)
end
