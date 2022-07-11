local tools = {}



tools.Tool = class("Tool", {list = {}})

function tools.Tool:disabled() end
function tools.Tool:panel() end
function tools.Tool:update() end
function tools.Tool:draw() end
function tools.Tool:mousepressed() end
function tools.Tool:mousereleased() end
function tools.Tool:mousemoved() end

function tools.Tool:registerTool(T)
    table.insert(self.list, T)
end

-- tile panel mixin

local autolayout = {{0,  1,  3,  2,  16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27},
                    {4,  5,  7,  6,  28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39},
                    {12, 13, 15, 14, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51},
                    {8,  9,  11, 10, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63}}

local TilePanelMx = {}

function TilePanelMx:tilePanel()
    -- tiles
    local tileSize = math.floor((app.tpw - 3) / 16)

    ui:stylePush {
        window = {
            spacing = {x = 0, y = 0},
        }
    }

    --ui:layoutRow("dynamic", 25*global_scale, 3)
    ui:layoutTemplateBegin(40*global_scale)
    ui:layoutTemplatePush("static", 40*global_scale)
    ui:layoutTemplatePush("dynamic")
    ui:layoutTemplatePush("dynamic")
    ui:layoutTemplateEnd()

    tileButton(app.currentTile, false, false, true)
    ui:spacing(1)
    app.showGarbageTiles = ui:checkbox("Show 2nd half", app.showGarbageTiles)

    -- spacing
    ui:layoutRow("dynamic", 1*global_scale, 0)

    for j = 0, app.showGarbageTiles and 15 or 7 do
        ui:layoutRow("static", tileSize, tileSize, 16)
        for i = 0, 15 do
            local n = i + j*16

            if tileButton(n, app.currentTile == n and not app.autotile) then
                if self.autotileEditO then
                    if app.autotile then
                        if self.autotileEditO >= 16 and n == 0 then
                            app.project.conf.autotiles[app.autotile][self.autotileEditO] = nil
                        else
                            app.project.conf.autotiles[app.autotile][self.autotileEditO] = n
                        end
                    end

                    updateAutotiles()

                    self.autotileEditO = nil
                    app.currentTile = app.project.conf.autotiles[app.autotile][15]
                else
                    app.currentTile = n
                    app.autotile = nil
                end
            end
        end
    end

    -- spacing
    ui:layoutRow("dynamic", 1*global_scale, 0)

    -- autotiles
    ui:layoutRow("dynamic", 25*global_scale, 3)
    ui:label("Autotiles:")
    ui:spacing(1)
    if ui:button("New Autotile") then
        local auto = {[0] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        table.insert(app.project.conf.autotiles, auto)

        updateAutotiles()
    end

    ui:layoutRow("static", tileSize, tileSize, #app.project.conf.autotiles)
    for k, auto in ipairs(app.project.conf.autotiles) do
        if tileButton(auto[5], app.autotile == k) then
            app.currentTile = auto[15]
            app.autotile = k

            self.autotileEditO = nil
        end
    end

    if app.autotile then
        ui:layoutRow("dynamic", 25*global_scale, 3)
        ui:label("Tileset: (click to edit)")
        ui:spacing(1)
        if ui:button("Delete Autotile") then
            table.remove(app.project.conf.autotiles, app.autotile)

            updateAutotiles()

            app.autotile = math.max(1, app.autotile - 1)
        end
    end

    -- check for missing autotile! can happen on undo/redo
    if not app.project.conf.autotiles[app.autotile] then
        app.autotile = nil
    end

    if app.autotile then
        for r = 1, 4 do
            ui:layoutRow("static", tileSize, tileSize, 16)
            for i = 1, #autolayout[r] do
                local o = autolayout[r][i]
                if tileButton(app.project.conf.autotiles[app.autotile][o] or 0, self.autotileEditO == o, o) then
                    self.autotileEditO = o
                end
            end
        end

        ui:layoutRow("dynamic", 50*global_scale, 1)
        ui:label("Autotile draws with the 16 tiles on the left, connecting them to each other and to any of the extra tiles on the right. This allows connecting to other deco tiles and tiles from other tilesets. Also works when erasing.", "wrap")
    end

    ui:stylePop()
end



-- Brush

tools.Brush = tools.Tool:extend("Brush"):with(TilePanelMx)
tools.Tool:registerTool(tools.Brush)

function tools.Brush:panel()
    self:tilePanel()
end

function tools.Brush:update(dt)
    if not ui:windowIsAnyHovered()
    and not love.keyboard.isDown("lalt")
    and not app.suppressMouse
    and (love.mouse.isDown(1) or love.mouse.isDown(2)) then
        local n = app.currentTile
        if love.mouse.isDown(2) then
            n = 0
        end

        local ti, tj = app:mouseOverTile()
        if ti then
            local room = app:activeRoom()

            app:activeRoom().data[ti][tj] = n

            if app.autotile then
                autotileWithNeighbors(app:activeRoom(), ti, tj, app.autotile)
            end
        end
    end
end

function tools.Brush:draw()
    app:drawMouseOverTile(nil, app.currentTile)
end



-- Rectangle

tools.Rectangle = tools.Tool:extend("Rectangle"):with(TilePanelMx)
tools.Tool:registerTool(tools.Rectangle)

function tools.Rectangle:panel()
    self:tilePanel()
end

function tools.Rectangle:draw()
    local ti, tj = app:mouseOverTile()

    if not self.rectangleI then
        app:drawMouseOverTile(nil, app.currentTile)
    elseif ti then
        local i, j, w, h = rectCont2Tiles(ti, tj, self.rectangleI, self.rectangleJ)
        app:drawColoredRect(app:activeRoom(), i*8, j*8, w*8, h*8, {0, 1, 0.5}, false)
    end
end

function tools.Rectangle:mousepressed(x, y, button)
    local ti, tj = app:mouseOverTile()

    if button == 1 or button == 2 then
        if ti then
            self.rectangleI, self.rectangleJ = ti, tj
        end
    end
end

function tools.Rectangle:mousereleased(x, y, button)
    local ti, tj = app:mouseOverTile()

    if ti and self.rectangleI then
        local room = app:activeRoom()

        local n = app.currentTile
        if button == 2 then
            n = 0
        end

        local i0, j0, w, h = rectCont2Tiles(self.rectangleI, self.rectangleJ, ti, tj)
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

    self.rectangleI, self.rectangleJ = nil, nil
end



-- Selection

tools.Select = tools.Tool:extend("Selection")
tools.Tool:registerTool(tools.Select)

function tools.Select:disabled()
    if app.project.selection then
        app:placeSelection()
    end
end

function tools.Select:draw()
    local ti, tj = app:mouseOverTile()

    if not self.selectTileI then
        app:drawMouseOverTile()
    elseif ti then
        local i, j, w, h = rectCont2Tiles(ti, tj, self.selectTileI, self.selectTileJ)
        app:drawColoredRect(app:activeRoom(), i*8, j*8, w*8, h*8, {0, 1, 0.5}, false)
    end
end

function tools.Select:mousepressed(x, y, button)
    local ti, tj = app:mouseOverTile()
    local mx, my = app:fromScreen(x, y)

    if button == 1 then
        if not app.project.selection then
            if ti then
                self.selectTileI, self.selectTileJ = ti, tj
            end
        else
            self.selectionMoveX,  self.selectionMoveY  = mx - app.project.selection.x, my - app.project.selection.y
            self.selectionStartX, self.selectionStartY = app.project.selection.x, app.project.selection.y
        end
    end
end

function tools.Select:mousereleased(x, y, button)
    local ti, tj = app:mouseOverTile()

    if ti and self.selectTileI then
        app:placeSelection()

        app:select(ti, tj, self.selectTileI, self.selectTileJ)
    end

    if app.project.selection and self.selectionMoveX then
        if app.project.selection.x == self.selectionStartX and app.project.selection.y == self.selectionStartY then
            app:placeSelection()
        end
    end

    self.selectTileI,    self.selectTileJ    = nil, nil
    self.selectionMoveX, self.selectionMoveY = nil, nil
end

function tools.Select:mousemoved(x, y, dx, dy)
    local mx, my = app:fromScreen(x, y)

    if self.selectionMoveX and app.project.selection then
        app.project.selection.x = roundto8(mx - self.selectionMoveX)
        app.project.selection.y = roundto8(my - self.selectionMoveY)
    end
end



-- Camera Trigger

tools.Camtrigger = tools.Tool:extend("Camera Trigger")
tools.Tool:registerTool(tools.Camtrigger)

function tools.Camtrigger:panel()
    ui:layoutRow("dynamic", 25*global_scale, 1)
    app.showCameraTriggers = ui:checkbox("Show camera triggers when not using the tool", app.showCameraTriggers)
    if app:selectedTrigger() then
        local trigger = app:selectedTrigger()

        local editX = {value = trigger.off_x}
        local editY = {value = trigger.off_y}

        ui:layoutRow("dynamic",25*global_scale,4)
        ui:label("x offset","centered")
        ui:edit("simple", editX)
        ui:label("y offset","centered")
        ui:edit("simple", editY)

        trigger.off_x = editX.value
        trigger.off_y = editY.value
    end
end

function tools.Camtrigger:draw()
    local ti, tj = app:mouseOverTile()

    if not self.camtriggerI then
        app:drawMouseOverTile({1,0.75,0})
    elseif ti then
        local i, j, w, h = rectCont2Tiles(ti, tj, self.camtriggerI, self.camtriggerJ)
        app:drawColoredRect(app:activeRoom(), i*8, j*8, w*8, h*8, {1,0.75,0}, false)
    end
end

function tools.Camtrigger:mousepressed(x, y, button)
    local ti, tj = app:mouseOverTile()
    if not ti then return end

    local hovered=app:hoveredTriggerN()
    if button == 1 then
        if love.keyboard.isDown("lctrl") then
            if not app:selectedTrigger() and hovered then
                app.selectedCamtriggerN = hovered
            end
            if app:selectedTrigger() then
                self.camtriggerMoveI, self.camtriggerMoveJ = ti, tj
            end
        else
            local hovered = app:hoveredTriggerN()
            if app:selectedTrigger() then
                app.selectedCamtriggerN = nil
                --deselect
            elseif hovered then
                app.selectedCamtriggerN = hovered
            else
                self.camtriggerI, self.camtriggerJ = ti, tj
            end
        end
    elseif button == 2 and love.keyboard.isDown("lctrl") then
        if not app:selectedTrigger() and hovered then
            app.selectedCamtriggerN = hovered
        end
        if app:selectedTrigger() then
            self.camtriggerSideI = sign(ti - app:selectedTrigger().x - app:selectedTrigger().w/2)
            self.camtriggerSideJ = sign(tj - app:selectedTrigger().y - app:selectedTrigger().h/2)
        end
        -- app.camtriggerSideI,app.camtriggerSideJ=ti,tj
    end
end

function tools.Camtrigger:mousemoved(x,y)
    local ti,tj = app:mouseOverTile()
    if not ti then return end

    local trigger = app:selectedTrigger()

    if self.camtriggerMoveI then
        trigger.x=trigger.x+(ti-self.camtriggerMoveI)
        trigger.y=trigger.y+(tj-self.camtriggerMoveJ)
        self.camtriggerMoveI,self.camtriggerMoveJ=ti,tj
    end
    if self.camtriggerSideI then
        if self.camtriggerSideI < 0 then
            local newx = math.min(ti, trigger.x + trigger.w-1)
            trigger.w = trigger.x - newx + trigger.w
            trigger.x = newx
        else
            trigger.w = math.max(ti - trigger.x + 1, 1)
        end
        if self.camtriggerSideJ < 0 then
            local newy = math.min(tj, trigger.y + trigger.h - 1)
            trigger.h = trigger.y - newy + trigger.h
            trigger.y = newy
        else
            trigger.h = math.max(tj - trigger.y + 1, 1)
        end
    end
end

function tools.Camtrigger:mousereleased(x, y, button)
    local ti, tj = app:mouseOverTile()

    if ti and self.camtriggerI then
        local room = app:activeRoom()
        local i0, j0, w, h = rectCont2Tiles(self.camtriggerI, self.camtriggerJ, ti, tj)
        local trigger={x=i0,y=j0,w=w,h=h,off_x="0",off_y="0"}
        table.insert(room.camtriggers, trigger)
        app.selectedCamtriggerN = #room.camtriggers
    end

    self.camtriggerI,     self.camtriggerJ     = nil, nil
    self.camtriggerMoveI, self.camtriggerMoveJ = nil, nil
    self.camtriggerSideI, self.camtriggerSideJ = nil, nil
end



-- Room Properties

tools.Room = tools.Tool:extend("Room")
tools.Tool:registerTool(tools.Room)

function tools.Room:panel()
    ui:layoutRow("static", 25*global_scale, 100*global_scale, 2)
    if ui:button("New Room") then
        local x, y = app:fromScreen(app.W/3, app.H/3)
        local room = newRoom(roundto8(x), roundto8(y), 16, 16)

        room.title = ""

        table.insert(app.project.rooms, room)
        app.room = #app.project.rooms
        app.roomAdded = true
    end
    if ui:button("Delete Room") then
        if app:activeRoom() then
            table.remove(app.project.rooms, app.room)
            if not app:activeRoom() then
                app.room = #app.project.rooms
            end
        end
    end

    local room = app:activeRoom()
    if room then
        local param_n = math.max(#app.project.conf.param_names,#room.params)

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
        room.hex = ui:checkbox("Store as hex string", room.hex or not fits_on_map)
        ui:stylePop()

        ui:layoutRow("dynamic", 25*global_scale, 5)
        ui:label("Level Exits:")
        for _,v in pairs({"left","bottom","right","top"}) do
            room.exits[v] = ui:checkbox(v, room.exits[v])
        end

        for i=1, param_n do
            ui:layoutRow("dynamic", 25*global_scale, {0.25,0.75} )
            ui:label(app.project.conf.param_names[i] or "")

            local t = {value=room.params[i] or 0}
            ui:edit("field", t)
            room.params[i] = t.value
        end
    end
end



tools.Project = tools.Tool:extend("Project")
tools.Tool:registerTool(tools.Project)

function tools.Project:panel()
    ui:layoutRow("static", 25*global_scale, 100*global_scale, 3)
    if ui:button("Open") then
        openFile()
    end
    if ui:button("Save") then
        saveFile(false)
    end
    if ui:button("Save as...") then
        saveFile(true)
    end

    ui:layoutRow("dynamic", 25*global_scale, {0.8, 0.1, 0.1})
    ui:label("Room parameter names:")
    if ui:button("+") then
        table.insert(app.project.conf.param_names, "")
    end
    if ui:button("-") then
        table.remove(app.project.conf.param_names, #app.project.param_names)
    end
    for i = 1, #app.project.conf.param_names do
        ui:layoutRow("dynamic", 25*global_scale, 1)

        local t = {value=app.project.conf.param_names[i]}
        ui:edit("field", t)
        app.project.conf.param_names[i] = t.value
    end
end

return tools