-- functions to read lines correctly for \r\n line endings

local function cr_file_lines(file)
    return function()
        return file:read("*l")
    end
end

-- file handling

function loadpico8(filename)
    love.graphics.setDefaultFilter("nearest", "nearest")

    local file, err = io.open(filename, "rb")

    local data = {}

    data.palette = {
        {0,  0,  0,  255},
        {29, 43, 83, 255},
        {126,37, 83, 255},
        {0,  135,81, 255},
        {171,82, 54, 255},
        {95, 87, 79, 255},
        {194,195,199,255},
        {255,241,232,255},
        {255,0,  77, 255},
        {255,163,0,  255},
        {255,240,36, 255},
        {0,  231,86, 255},
        {41, 173,255,255},
        {131,118,156,255},
        {255,119,168,255},
        {255,204,170,255}
    }

    local sections = {}
    local cursec = nil
    for line in cr_file_lines(file) do
        local sec = string.match(line, "^__([%a_]+)__$")
        if sec then
            cursec = sec
            sections[sec] = {}
        elseif cursec then
            table.insert(sections[cursec], line)
        end
    end
    file:close()
    local p8font=love.image.newImageData("pico-8_font.png")
    local function toGrey(x,y,r,g,b,a)
        return r*194/255,g*195/255,b*199/255,a
    end
    p8fontGrey=love.image.newImageData(p8font:getWidth(),p8font:getHeight(),p8font:getFormat(),p8font)
    p8fontGrey:mapPixel(toGrey)
    local function get_font_quad(digit)
        if digit<10 then
            return 8*digit,24,4,8
        else
            return 8*(digit-9),48,4,8
        end
    end
    local spritesheet_data = love.image.newImageData(128, 128)
    for j = 0, spritesheet_data:getHeight()/2 - 1 do
        local line = sections["gfx"] and sections["gfx"][j + 1] or "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        for i = 0, spritesheet_data:getWidth() - 1 do
            local s = string.sub(line, 1 + i, 1 + i)
            local b = fromhex(s)
            local c = data.palette[b + 1]
            spritesheet_data:setPixel(i, j, c[1]/255, c[2]/255, c[3]/255, 1)
        end
    end

    for j =8,15 do
        for i = 0, 15 do
            local id=i+16*(j-8)
            local d1=math.floor(id/16)
            local d2=id%16
            --spritesheet_data:paste(p8font,8*i,8*j,get_font_quad(d1))
            spritesheet_data:paste(p8fontGrey,8*i,8*j,get_font_quad(d1))
            spritesheet_data:paste(p8font,8*i+4,8*j,get_font_quad(d2))
        end
    end

    data.spritesheet = love.graphics.newImage(spritesheet_data)

    data.quads = {}
    for i = 0, 15 do
        for j = 0, 15 do
            data.quads[i + j*16] = love.graphics.newQuad(i*8, j*8, 8, 8, data.spritesheet:getDimensions())
        end
    end

    data.map = {}
    for i = 0, 127  do
        data.map[i] = {}
        for j = 0, 31 do
            local line = sections["map"] and sections["map"][j + 1] or "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            local s = string.sub(line, 1 + 2*i, 2 + 2*i)
            data.map[i][j] = fromhex(s)
        end
        for j = 32, 63 do
            local i_ = i%64
            local j_ = i <= 63 and j*2 or j*2 + 1
            local line = sections["gfx"][j_ + 1] or "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            local s = string.sub(line, 1 + 2*i_, 2 + 2*i_)
            data.map[i][j] = fromhex_swapnibbles(s)
        end
    end

    data.rooms = {}
    data.roomBounds = {}

    -- code: look for the magic comment
    local code = table.concat(sections["lua"], "\n")

    -- get configuration code, if exists
    local evhconf = string.match(code, "%-%-@conf([^@]+)%-%-@")
    if evhconf then
        evhconf = string.match(evhconf, "%-%-%[%[([^@]+)%]%]")
        if evhconf then
            local chunk, err = loadstring(evhconf)

            if not err then
                local env = {}
                chunk = setfenv(chunk, env)
                chunk()

                data.param_names = env.param_names
                data.autotiles = env.autotiles
            end
        end
    end

    local evh = string.match(code, "%-%-@begin([^@]+)%-%-@end")
    local levels, mapdata, camera_offsets
    if evh then
        -- get names of parameters from commented string
        local param_string=evh:match("%-%-\"x,y,w,h,exit_dirs,?(.-)\"")
        data.param_names = data.param_names or split(param_string or "")

        -- cut out comments - loadstring doesn't parse them for some reason
        evh = string.gsub(evh, "%-%-[^\n]*\n", "")
        evh = string.gsub(evh, "//[^\n]*\n", "")

        local chunk, err = loadstring(evh)
        if not err then
            local env = {}
            chunk = setfenv(chunk, env)
            chunk()

            levels, mapdata, camera_offsets = env.levels, env.mapdata, env.camera_offsets
        end
    end
    -- parameter names default to none
    data.param_names = data.param_names or {}

    mapdata = mapdata or {}

    -- flatten levels and mapdata
    local lvls = {}
    if levels then
        for n, s in pairs(levels) do
            table.insert(lvls, {n, s, mapdata[n]})
        end
    end
    table.sort(lvls, function(p1, p2) return p1[1] < p2[1] end)
    levels, mapdata = {}, {}
    for n, p in pairs(lvls) do
        levels[n] = p[2]
        mapdata[n] = p[3]
    end

    -- load levels
    if levels[1] then
        for n, s in pairs(levels) do
            local x, y, w, h, exits, params= string.match(s, "^([^,]*),([^,]*),([^,]*),([^,]*),?([^,]*),?(.*)$")
            x, y, w, h, exits = tonumber(x), tonumber(y), tonumber(w), tonumber(h), exits or "0b0001"
            params=split(params or "")
            if x and y and w and h then -- this confirms they're there and they're numbers
                data.rooms[n] = newRoom(x*128, y*128, w*16, h*16)
                data.rooms[n].exits={left=exits:sub(3,3)=="1", bottom=exits:sub(4,4)=="1", right=exits:sub(5,5)=="1", top=exits:sub(6,6)=="1"}
                data.rooms[n].hex=false
                data.rooms[n].params=params
            else
                print("wat", s)
            end
        end
    else
        for J = 0, 3 do
            for I = 0, 7 do
                local room=newRoom(I*128, J*128, 16, 16)
                room.hex = false
                --b.title=""
                table.insert(data.rooms, room)
            end
        end
    end

    -- load mapdata
    if mapdata then
        for n, levelstr in pairs(mapdata) do
            local room = data.rooms[n]
            if room then
                loadroomdata(room, levelstr)
                room.hex=true
            end
        end
    end

    -- fill rooms with no mapdata from p8 map
    for n, room in ipairs(data.rooms) do
        if not room.hex then
            for i = 0, room.w - 1 do
                for j = 0, room.h - 1 do
                    local i1, j1 = div8(room.x) + i, div8(room.y) + j
                    if i1 >= 0 and i1 < 128 and j1 >= 0 and j1 < 64 then
                        room.data[i][j] = data.map[i1][j1]
                    else
                        room.data[i][j] = 0
                    end
                end
            end
        end
    end

    if camera_offsets then
        for n,tbl in pairs(camera_offsets) do
            for _,t in pairs(tbl) do
                args={}
                -- strip leading and trailing whitespace
                for d in t:gmatch("%s*[^,]+%s*") do
                    -- off_x and off_y are strings and not numbers
                    table.insert(args,#args<4 and tonumber(d) or d)
                end
                if data.rooms[n] then
                    table.insert(data.rooms[n].camtriggers,{x=args[1],y=args[2],w=args[3],h=args[4],off_x=args[5],off_y=args[6]})
                end
            end
        end
    end
    return data
end

function openPico8(filename)
    newProject()

    -- loads into global p8data as well, for spritesheet
    p8data = loadpico8(filename)
    project.rooms = p8data.rooms
    --store names of parameters, in order to show in the ui
    project.param_names = p8data.param_names
    project.autotiles = p8data.autotiles or defaultAutotiles()

    updateAutotiles()

    app.openFileName = filename

    return true
end

function savePico8(filename)
    local map = fill2d0s(128, 64)

    for _, room in ipairs(project.rooms) do
        if not room.hex then
            local i0, j0 = div8(room.x), div8(room.y)
            for i = 0, room.w - 1 do
                for j = 0, room.h - 1 do
                    if map[i0+i] then
                        map[i0+i][j0+j] = room.data[i][j]
                    end
                end
            end
        end
    end

    local file = io.open(filename, "rb")
    if not file and app.openFileName then
        file = io.open(app.openFileName, "rb")
    end
    if not file then
        return false
    end

    local out = {}

    local ln = 1
    local gfxstart, mapstart
    for line in cr_file_lines(file) do
        table.insert(out, line)
        ln = ln + 1
    end
    file:close()

    local levels, mapdata, camera_offsets = {}, {}, {}
    for n = 1, #project.rooms do
        local room = project.rooms[n]
        local exit_string="0b"
        for _,v in pairs({"left","bottom","right","top"}) do
            if room.exits[v] then
                exit_string=exit_string.."1"
            else
                exit_string=exit_string.."0"
            end
        end
        levels[n] = string.format("%g,%g,%g,%g,%s", room.x/128, room.y/128, room.w/16, room.h/16, exit_string)
        for _,v in ipairs(room.params) do
            levels[n]=levels[n]..","..v
        end

        if room.hex then
            mapdata[n] = dumproomdata(room)
        end

        if room.camtriggers then
            camera_offsets[n]={}
            for _,t in pairs(room.camtriggers) do
                local trigger_str=string.format("%d,%d,%d,%d,%s,%s",t.x,t.y,t.w,t.h,t.off_x,t.off_y)
                table.insert(camera_offsets[n],trigger_str)
            end
        end
    end
    -- map section

    -- start out by making sure both sections exist, and are sized to max size


    local gfxexist, mapexist=false,false
    for k = 1, #out do
        if out[k] == "__gfx__" then
            gfxexist=true
        elseif out[k] == "__map__" then
            mapexist=true
        end
    end

    if not gfxexist then
        table.insert(out,"__gfx__")
    end
    if not mapexist then
        table.insert(out,"__map__")
    end

    for k,v in ipairs(out) do
        if out[k]=="__gfx__" or out[k]=="__map__" then
            local j=k+1
            while j<#out and not out[j]:match("__%a+__") do
                j=j+1
            end
            local emptyline=""
            for i=1,out[k]=="__gfx__" and 128 or 256 do
                emptyline=emptyline.."0"
            end
            for i=j,k+(out[k]=="__gfx__" and 128 or 32) do
                table.insert(out,i,emptyline)
            end
        end
    end
    local gfxstart, mapstart
    for k = 1, #out do
        if out[k] == "__gfx__" then
            gfxstart = k
        elseif out[k] == "__map__" then
            mapstart = k
        end
    end
    if not (mapstart and gfxstart) then
        error("uuuh")
    end

    for j = 0, 31 do
        local line = ""
        for i = 0, 127 do
            line = line .. tohex(map[i][j])
        end
        out[mapstart+j+1] = line
    end
    for j = 32, 63 do
        local line = ""
        for i = 0, 127 do
            line = line .. tohex_swapnibbles(map[i][j])
        end
        out[gfxstart+(j-32)*2+65] = string.sub(line, 1, 128)
        out[gfxstart+(j-32)*2+66] = string.sub(line, 129, 256)
    end

    local cartdata=table.concat(out, "\n")

    -- add configuration block if missing
    if not cartdata:match("%-%-@conf") then
        cartdata = cartdata:gsub("%-%-@begin", "--@conf\n--[[ ]]\n--@begin")
    end

    -- rewrite configuration block
    local confcode = "param_names = "..dumplualine(project.param_names).."\nautotiles = "..dumplualine(project.autotiles)
    cartdata = cartdata:gsub("%-%-@conf.-%-%-%[%[.-%]%]", "--@conf\n--[["..confcode.."\n]]")

    -- write to levels table without overwriting the code
    cartdata = cartdata:gsub("(%-%-@begin.*levels%s*=%s*){.-}(.*%-%-@end)","%1"..dumplua(levels).."%2")
    cartdata = cartdata:gsub("(%-%-@begin.*mapdata%s*=%s*){.-}(.*%-%-@end)","%1"..dumplua(mapdata).."%2")
    cartdata = cartdata:gsub("(%-%-@begin.*camera_offsets%s*=%s*)%b{}(.*%-%-@end)","%1"..dumplua(camera_offsets).."%2")

    --remove playtesting inject if one already exists:
    cartdata = cartdata:gsub("(%-%-@begin.*)local __init.-\n(.*%-%-@end)","%1".."%2")
    if app.playtesting and app.room then
        local inject = "local __init = _init function _init() __init() load_level("..app.room..") music(-1)"
        if app.playtesting == 2 then
            inject = inject.." max_djump=2"
        end
        inject = inject.." end"
        cartdata=cartdata:gsub("%-%-@end",inject.."\n--@end")
    end
    file = io.open(filename, "wb")
    file:write(cartdata)
    file:close()

    app.saveFileName = filename

    return true
end
