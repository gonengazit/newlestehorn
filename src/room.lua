function newRoom(x, y, w, h)
    local room = {
        x = x or 0,
        y = y or 0,
        w = w or 16,
        h = h or 16,
        hex=true,
        data = {},
        exits={left=false, bottom=false, right=false, top=true},
        params = {},
        title = "",
        camtriggers={}
    }
    room.data = fill2d0s(room.w, room.h)

    return room
end

function drawRoom(room, p8data, highlight)
    love.graphics.setColor(1, 1, 1)
    for i = 0, room.w - 1 do
        for j = 0, room.h - 1 do
            local n = room.data[i][j]
            if not p8data.quads[n] then print(n) end
            if not highlight or n~=0 then
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(p8data.spritesheet, p8data.quads[n], room.x + i*8, room.y + j*8)
            end
        end
    end

    if highlight then
        drawColoredRect(room, 0, 0, room.w*8, room.h*8, {0, 1, 0.5}, true)
    end

    local highlighted = app.tool == "camtrigger" and (project.selected_camtrigger or hoveredTrigger())
    --TODO: draw selected and hovered in different colors maybe
    for _,trigger in ipairs(room.camtriggers) do
        local ti, tj = mouseOverTile()

        local col
        if trigger == highlighted then
            if project.selected_camtrigger then
                col = {0.5,1,0}
            else
                col = {1,0.9,0}
            end
        else
            col = {1,0.75,0}
        end

        drawColoredRect(room, trigger.x*8, trigger.y*8, trigger.w*8, trigger.h*8, col, true)
    end
end
