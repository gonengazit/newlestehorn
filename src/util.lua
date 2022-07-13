local util = {}



function isempty(t)
    for k, v in pairs(t) do
        return false
    end
    return true
end

function fromhex(s)
    return tonumber(s, 16)
end

function fromhex_swapnibbles(s)
    local x = fromhex(s)
    return math.floor(x/16) + 16*(x%16)
end

local hext = { [0] = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 'a', 'b', 'c', 'd', 'e', 'f'}

function tohex(b)
    return hext[math.floor(b/16)]..hext[b%16]
end

function tohex_swapnibbles(b)
    return hext[b%16]..hext[math.floor(b/16)]
end

function roundto8(x)
    return 8*math.floor(x/8 + 1/2)
end

function sign(x)
    return x > 0 and 1 or -1
end

function fill2d0s(w, h)
    local a = {}
    for i = 0, w - 1 do
        a[i] = {}
        for j = 0, h - 1 do
            a[i][j] = 0
        end
    end
    return a
end

function rectCont2Tiles(i, j, i_, j_)
    return math.min(i, i_), math.min(j, j_), math.abs(i - i_) + 1, math.abs(j - j_) + 1
end

function div8(x)
    return math.floor(x/8)
end

function dumplua(t)
    return serpent.block(t, {comment = false, metatostring = false})
    
end

function dumplualine(t)
    return serpent.line(t, {compact = true, comment = false, metatostring = false, keyignore = {class = true, super = true}})
end

function loadlua(s)
    f, err = loadstring("return "..s)
    if err then
        return nil, err
    else
        return f()
    end
end

local alph_ = "abcdefghijklmnopqrstuvwxyz"
local alph = {[0] = " "}
for i = 1, 26 do
    alph[i] = string.sub(alph_, i, i)
end

function b26(n)
    local m, n = math.floor(n / 26), n % 26
    if m > 0 then
        return b26(m - 1) .. alph[n + 1]
    else
        return alph[n + 1]
    end
end

function split(str)
    -- emulate pico8's split
    -- split , sperated list, auto convert numbers to ints
    local tbl={}
    for val in string.gmatch(str, '([^,]+)') do
        if tonumber(val) ~= nil then
            val=tonumber(val)
        end
        table.insert(tbl,val)
    end
    return tbl
end

function contains(t, v)
    for k, w in pairs(t) do
        if v == w then return true end
    end
    return false
end

function printbg(text, x, y, fgcol, bgcol, centerx, centery)
    local font = love.graphics.getFont()
    local w, h = font:getWidth(text), font:getHeight(text)

    if centerx then
        x = x - w/2
    end
    if centery then
        y = y - h/2
    end

    love.graphics.setColor(bgcol)
    love.graphics.rectangle("fill", x - 4, y - 4, w + 8, h + 8)

    love.graphics.setColor(fgcol)
    love.graphics.print(text, x, y)
end



function util.instanceFromTable(C, t)
    local o = C:create()
    for k, v in pairs(t) do
        o[k] = v
    end
    return o
end

function util.upscale(imgdata, upscale)
    local w, h = imgdata:getDimensions()
    local scaled_imgdata = love.image.newImageData(w * upscale, h * upscale)

    for x = 0, scaled_imgdata:getWidth() - 1 do
        for y = 0, scaled_imgdata:getHeight() - 1 do
            local r, g, b, a = imgdata:getPixel(math.floor(x/upscale), math.floor(y/upscale))
            scaled_imgdata:setPixel(x, y, r, g, b, a)
        end
    end

    return scaled_imgdata
end



return util