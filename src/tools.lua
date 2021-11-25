tools = {}

-- this defines the order of tools on the panel
toolslist = {"brush", "rectangle", "select", "camtrigger"}



tools.brush = {}
tools.brush.name = "Brush"

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



tools.rectangle = {}
tools.rectangle.name = "Rectangle"

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



tools.select = {}
tools.select.name = "Selection"

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



tools.camtrigger = {}
tools.camtrigger.name = "Camtrigger"

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

    if button == 1 then
        if ti then
            local hovered=hoveredTrigger()
            if project.selected_camtrigger then
                project.selected_camtrigger=false
                --rn deselect
                -- TODO: implement resizing and moving (like rooms)
            elseif hovered then
                project.selected_camtrigger=hovered
            else
                app.camtriggerI, app.camtriggerJ = ti, tj
            end
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
        app.editCamtrigger=trigger
        app.editCamtriggerTable={x={value=0},y={value=0}}
        project.selected_camtrigger=trigger
    end

    app.camtriggerI, app.camtriggerJ = nil, nil
end
