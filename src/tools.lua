tools = {}

-- this defines the order of tools on the panel
toolslist = {"brush", "rectangle", "select", "camtrigger", "roomproperties"}



baseTool = {}
baseTool.__index = baseTool
function baseTool.onenabled() end
function baseTool.ondisabled() end
function baseTool.panel() end
function baseTool.update() end
function baseTool.draw() end
function baseTool.mousepressed() end
function baseTool.mousereleased() end
function baseTool.mousemoved() end

function newTool(name)
    local tool = {}
    tool.name = name

    setmetatable(tool, baseTool)

    return tool
end



-- common tool panels

function tilePanel()
    -- tiles
    ui:layoutRow("dynamic", 25*global_scale, 1)
    ui:label("Tiles:")
    for j = 0, app.showGarbageTiles and 15 or 7 do
        ui:layoutRow("static", 8*tms, 8*tms, 16)
        for i = 0, 15 do
            local n = i + j*16
            if tileButton(n, app.currentTile == n and not app.autotile) then
                app.currentTile = n
                app.autotile = nil
            end
        end
    end

    -- autotiles
    ui:layoutRow("dynamic", 25*global_scale, 1)
    ui:label("Autotiles:")
    ui:layoutRow("static", 8*tms, 8*tms, #autotiles)
    for k, auto in ipairs(autotiles) do
        if tileButton(auto[5], app.currentTile == auto[15] and app.autotile) then
            app.currentTile = auto[15]
            app.autotile = k
        end
    end
end



-- Brush

tools.brush = newTool("Brush")

function tools.brush.panel()
    tilePanel()
end

function tools.brush.update(dt)
    if not ui:windowIsAnyHovered() and not love.keyboard.isDown("lalt") and (love.mouse.isDown(1) or love.mouse.isDown(2)) then
        local n = app.currentTile
        if love.mouse.isDown(2) then
            n = 0
        end

        local ti, tj = mouseOverTile()
        if ti then
            local room = activeRoom()

            activeRoom().data[ti][tj] = n

            if app.autotile then
                autotileWithNeighbors(activeRoom(), ti, tj, app.autotile)
            end
        end
    end
end

function tools.brush.draw()
    drawMouseOverTile()
end



-- Rectangle

tools.rectangle = newTool("Rectangle")

function tools.rectangle.panel()
    tilePanel()
end

function tools.rectangle.draw()
    local ti, tj = mouseOverTile()

    if not app.rectangleI then
        drawMouseOverTile()
    elseif ti then
        local i, j, w, h = rectCont2Tiles(ti, tj, app.rectangleI, app.rectangleJ)
        drawColoredRect(activeRoom(), i*8, j*8, w*8, h*8, {0, 1, 0.5}, false)
    end
end

function tools.rectangle.mousepressed(x, y, button)
    local ti, tj = mouseOverTile()

    if button == 1 or button == 2 then
        if ti then
            app.rectangleI, app.rectangleJ = ti, tj
        end
    end
end

function tools.rectangle.mousereleased(x, y, button)
    local ti, tj = mouseOverTile()

    if ti and app.rectangleI then
        local room = activeRoom()

        local n = app.currentTile
        if button == 2 then
            n = 0
        end

        local i0, j0, w, h = rectCont2Tiles(app.rectangleI, app.rectangleJ, ti, tj)
        for i = i0, i0 + w - 1 do
            for j = j0, j0 + h - 1 do
                room.data[i][j] = n
            end
        end

        if app.autotile then
            for i = i0, i0 + w - 1 do
                autotileWithNeighbors(room, i, j0, app.autotile)
                autotileWithNeighbors(room, i, j0 + h - 1, app.autotile)
            end
            for j = j0 + 1, j0 + h - 2 do
                autotileWithNeighbors(room, i0, j, app.autotile)
                autotileWithNeighbors(room, i0 + w - 1, j, app.autotile)
            end
        end
    end

    app.rectangleI, app.rectangleJ = nil, nil
end



-- Selection

tools.select = newTool("Selection")

function tools.select.ondisabled()
    if project.selection then
        placeSelection()
    end
end

function tools.select.draw()
    local ti, tj = mouseOverTile()

    if not app.selectTileI then
        drawMouseOverTile()
    elseif ti then
        local i, j, w, h = rectCont2Tiles(ti, tj, app.selectTileI, app.selectTileJ)
        drawColoredRect(activeRoom(), i*8, j*8, w*8, h*8, {0, 1, 0.5}, false)
    end
end

function tools.select.mousepressed(x, y, button)
    local ti, tj = mouseOverTile()
    local mx, my = fromScreen(x, y)

    if button == 1 then
        if not project.selection then
            if ti then
                app.selectTileI, app.selectTileJ = ti, tj
            end
        else
            project.selectionMoveX, project.selectionMoveY = mx - project.selection.x, my - project.selection.y
            project.selectionStartX, project.selectionStartY = project.selection.x, project.selection.y
        end
    end
end

function tools.select.mousereleased(x, y, button)
    local ti, tj = mouseOverTile()

    if ti and app.selectTileI then
        placeSelection()

        select(ti, tj, app.selectTileI, app.selectTileJ)
    end

    if project.selection and project.selectionMoveX then
        if project.selection.x == project.selectionStartX and project.selection.y == project.selectionStartY then
            placeSelection()
        end
    end

    app.selectTileI, app.selectTileJ = nil, nil
    project.selectionMoveX, project.selectionMoveY = nil, nil
end



-- Camera Trigger

tools.camtrigger = newTool("Camera Trigger")

function tools.camtrigger.ondisabled()
    app.selected_camtrigger = nil
end

function tools.camtrigger.panel()
    if app.selected_camtrigger then
        local editX = {value = app.selected_camtrigger.off_x}
        local editY = {value = app.selected_camtrigger.off_y}

        ui:layoutRow("dynamic",25*global_scale,4)
        ui:label("x offset","centered")
        ui:edit("simple", editX)
        ui:label("y offset","centered")
        ui:edit("simple", editY)

        app.selected_camtrigger.off_x = editX.value
        app.selected_camtrigger.off_y = editY.value
    end
end

function tools.camtrigger.draw()
    local ti, tj = mouseOverTile()

    if not app.camtriggerI then
        drawMouseOverTile({1,0.75,0})
    elseif ti then
        local i, j, w, h = rectCont2Tiles(ti, tj, app.camtriggerI, app.camtriggerJ)
        drawColoredRect(activeRoom(), i*8, j*8, w*8, h*8, {1,0.75,0}, false)
    end
end

function tools.camtrigger.mousepressed(x, y, button)
    local ti, tj = mouseOverTile()

    if not ti then return end 
    if button == 1 then
        if love.keyboard.isDown("lctrl") then 
            if app.selected_camtrigger then 
                app.camtriggerMoveI,app.camtriggerMoveJ=ti,tj
            end 
        else
            local hovered=hoveredTrigger()
            if app.selected_camtrigger then
                app.selected_camtrigger=false
                --deselect
            elseif hovered then
                app.selected_camtrigger=hovered
            else
                app.camtriggerI, app.camtriggerJ = ti, tj
            end
        end
    elseif button == 2 and love.keyboard.isDown("lctrl") and app.selected_camtrigger then 
        app.camtriggerSideI = sign(ti - app.selected_camtrigger.x - app.selected_camtrigger.w/2)
        app.camtriggerSideJ = sign(tj - app.selected_camtrigger.y - app.selected_camtrigger.h/2)
        -- app.camtriggerSideI,app.camtriggerSideJ=ti,tj
    end
end

function tools.camtrigger.mousemoved(x,y)
    local ti,tj = mouseOverTile()
    if not ti then return end 
    if app.camtriggerMoveI then 
        app.selected_camtrigger.x=app.selected_camtrigger.x+(ti-app.camtriggerMoveI)
        app.selected_camtrigger.y=app.selected_camtrigger.y+(tj-app.camtriggerMoveJ)
        app.camtriggerMoveI,app.camtriggerMoveJ=ti,tj
    end 
    if app.camtriggerSideI then 
        if app.camtriggerSideI < 0 then 
            local newx = math.min(ti,app.selected_camtrigger.x+app.selected_camtrigger.w-1)
            app.selected_camtrigger.w = app.selected_camtrigger.x - newx + app.selected_camtrigger.w
            app.selected_camtrigger.x = newx
        else
            app.selected_camtrigger.w = math.max(ti-app.selected_camtrigger.x+1,1)
        end 
        if app.camtriggerSideJ < 0 then 
            local newy = math.min(tj,app.selected_camtrigger.y+app.selected_camtrigger.h-1)
            app.selected_camtrigger.h = app.selected_camtrigger.y - newy + app.selected_camtrigger.h
            app.selected_camtrigger.y = newy
        else
            app.selected_camtrigger.h=math.max(tj-app.selected_camtrigger.y+1,1)
        end 
    end 
end

function tools.camtrigger.mousereleased(x, y, button)
    local ti, tj = mouseOverTile()

    if ti and app.camtriggerI then
        local room = activeRoom()
        local i0, j0, w, h = rectCont2Tiles(app.camtriggerI, app.camtriggerJ, ti, tj)
        local trigger={x=i0,y=j0,w=w,h=h,off_x=0,off_y=0}
        table.insert(room.camtriggers,trigger)
        app.selected_camtrigger=trigger
    end

    app.camtriggerI, app.camtriggerJ = nil, nil
    app.camtriggerMoveI,app.camtriggerMoveJ=nil, nil
    app.camtriggerSideI,app.camtriggerSideJ=nil, nil
end



-- Room Properties

tools.roomproperties = newTool("Room Properties")

function tools.roomproperties.panel()
    local room = activeRoom()
    if room then
        local param_n = math.max(#project.param_names,#room.params)

        local x,y=div8(room.x),div8(room.y)
        local fits_on_map=x>=0 and x+room.w<=128 and y>=0 and y+room.h<=64
        ui:layoutRow("dynamic",25*global_scale,1)
        if not fits_on_map then
            local style={}
            for k,v in pairs({"text normal", "text hover", "text active"}) do
                style[v]="#707070"
            end
            for k,v in pairs({"normal", "hover", "active"}) do
                style[v]=checkmarkWithBg -- show both selected and unselected as having a check to avoid nukelear limitations
                -- kinda hacky but it works decently enough
            end
            ui:stylePush({['checkbox']=style})

        else
            ui:stylePush({})
        end
        room.hex = ui:checkbox("Level Stored As Hex", room.hex or not fits_on_map)
        ui:stylePop()

        ui:layoutRow("dynamic", 25*global_scale, 5)
        ui:label("Level Exits:")
        for _,v in pairs({"left","bottom","right","top"}) do
            room.exits[v] = ui:checkbox(v, room.exits[v])
        end

        for i=1, param_n do
            ui:layoutRow("dynamic", 25*global_scale, {0.25,0.75} )
            ui:label(project.param_names[i] or "")

            local t = {value=room.params[i] or 0}
            ui:edit("field", t)
            room.params[i] = t.value
        end
    end
end
