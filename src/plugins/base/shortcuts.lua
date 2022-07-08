local keyboard = require 'plugins.base.keyboard'
local tools = require 'plugins.base.tools'

local shortcuts = {}

-- FILE OPERATIONS

shortcuts.Open = keyboard.Shortcut:extend("Open", {input = "ctrl o"})
function shortcuts.Open:run()
    openFile()
end

shortcuts.Save = keyboard.Shortcut:extend("Save", {input = "ctrl s"})
function shortcuts.Save:run()
    saveFile(false)
end

shortcuts.SaveAs = keyboard.Shortcut:extend("SaveAs", {input = "ctrl shift s"})
function shortcuts.SaveAs:run()
    saveFile(true)
end



-- UNDO/REDO

shortcuts.Undo = keyboard.Shortcut:extend("Undo", {input = "ctrl z", repeatable = true})
function shortcuts.Undo:run()
    if app.historyN >= 2 then
        app.historyN = app.historyN - 1

        local err
        project, err = loadproject(app.history[app.historyN])
        if err then error(err) end
    end

    if not app:activeRoom() then app.room = nil end
end

shortcuts.Redo = keyboard.Shortcut:extend("Redo", {input = "ctrl shift z", repeatable = true})
function shortcuts.Redo:run()
    if app.historyN <= #app.history - 1 then
        app.historyN = app.historyN + 1

        local err
        project, err = loadproject(app.history[app.historyN])
        if err then error(err) end
    end

    if not app:activeRoom() then app.room = nil end
end



-- SELECTION

shortcuts.SelectAll = keyboard.Shortcut:extend("SelectAll", {input = "ctrl a"})
function shortcuts.SelectAll:run()
    if app:activeRoom() then
        switchTool(tools.Select)
        select(0, 0, app:activeRoom().w - 1, app:activeRoom().h - 1)
    end
end

shortcuts.PlaceSelection = keyboard.Shortcut:extend("PlaceSelection", {input = "return"})
function shortcuts.PlaceSelection:run()
    placeSelection()
end

shortcuts.DeleteSelection = keyboard.Shortcut:extend("DeleteSelection", {input = "delete"})
function shortcuts.DeleteSelection:run()
    project.selection = nil

    local room = app:activeRoom()
    if app.selectedCamtriggerN and room then
        table.remove(room.camtriggers, app.selectedCamtriggerN)
        app.selectedCamtriggerN = nil
    end
end


-- COPY/CUT/PASTE

shortcuts.Cut = keyboard.Shortcut:extend("Cut", {input = "ctrl x"})
function shortcuts.Cut:run()
    if project.selection then
        local s = dumplualine {"selection", project.selection}
        love.system.setClipboardText(s)
        project.selection = nil

        showMessage("Cut")
    end
end

shortcuts.CutRoom = keyboard.Shortcut:extend("CutRoom", {input = "ctrl shift x"})
function shortcuts.CutRoom:run()
    if app:activeRoom() then
        local s = dumplualine {"room", app:activeRoom()}
        love.system.setClipboardText(s)
        table.remove(project.rooms, app.room)
        app.room = nil

        showMessage("Cut room")
    end
end

shortcuts.Copy = keyboard.Shortcut:extend("Copy", {input = "ctrl c"})
function shortcuts.Copy:run()
    if project.selection then
        local s = dumplualine {"selection", project.selection}
        love.system.setClipboardText(s)
        placeSelection()

        showMessage("Copied")
    end
end

shortcuts.CopyRoom = keyboard.Shortcut:extend("CopyRoom", {input = "ctrl shift c"})
function shortcuts.CopyRoom:run()
    if app:activeRoom() then
        local s = dumplualine {"room", app:activeRoom()}
        love.system.setClipboardText(s)

        showMessage("Copied room")
    end
end

shortcuts.Paste = keyboard.Shortcut:extend("Paste", {input = "ctrl v"})
function shortcuts.Paste:run()
    local mx, my = getMouse()
    
    placeSelection() -- to clean selection first

    local t, err = loadlua(love.system.getClipboardText())
    if not err then
        if type(t) == "table" then
            if t[1] == "selection" then
                local s = t[2]
                project.selection = s
                project.selection.x = roundto8(mx - s.w*4)
                project.selection.y = roundto8(my - s.h*4)
                switchTool(tools.Select)

                showMessage("Pasted")
            elseif t[1] == "room" then
                local r = t[2]
                r.x = roundto8(mx - r.w*4)
                r.y = roundto8(my - r.h*4)
                table.insert(project.rooms, r)
                app.room = #project.rooms
            else
                err = true
            end
        else
            err = true
        end
    end
    if err then
        showMessage("Failed to paste (did you paste something you're not supposed to?)")
    end
end



-- ROOMS

shortcuts.NewRoom = keyboard.Shortcut:extend("NewRoom", {input = "n"})
function shortcuts.NewRoom:run()
    local mx, my = getMouse()
    local room = newRoom(roundto8(mx - 64), roundto8(my - 64), 16, 16)

    room.title = ""

    table.insert(project.rooms, room)
    app.room = #project.rooms
    app.roomAdded = true
end

shortcuts.DeleteRoom = keyboard.Shortcut:extend("DeleteRoom", {input = "shift delete"})
function shortcuts.DeleteRoom:run()
    if app:activeRoom() then
        table.remove(project.rooms, app.room)
        if not app:activeRoom() then
            app.room = #project.rooms
        end
    end
end



-- TOGGLES

shortcuts.ToggleToolPanel = keyboard.Shortcut:extend("ToggleToolPanel", {input = "space"})
function shortcuts.ToggleToolPanel:run()
    app.showToolPanel = not app.showToolPanel
end

shortcuts.TogglePlaytesting = keyboard.Shortcut:extend("TogglePlaytesting", {input = "tab"})
function shortcuts.TogglePlaytesting:run()
    if not app.playtesting then
        app.playtesting = 1
    elseif app.playtesting == 1 then
        app.playtesting = 2
    else
        app.playtesting = false
    end
end

shortcuts.ToggleGarbageTiles = keyboard.Shortcut:extend("ToggleGarbageTiles", {input = "ctrl h"})
function shortcuts.ToggleGarbageTiles:run()
    app.showGarbageTiles = not app.showGarbageTiles
end

shortcuts.ToggleCameraTriggers = keyboard.Shortcut:extend("ToggleCameraTriggers", {input = "ctrl t"})
function shortcuts.ToggleCameraTriggers:run()
    app.showCameraTriggers = not app.showCameraTriggers
end



-- NAVIGATION

-- this one's a bit more hardcodey for now
shortcuts.SwitchRoom = keyboard.Shortcut:extend("SwitchRoom", {input = "", repeatable = true})
function shortcuts.SwitchRoom:checkModifiers()
    return not love.keyboard.isDown("lctrl") and not love.keyboard.isDown("lalt")
end
function shortcuts.SwitchRoom:checkKey(key)
    return key == "up" or key == "down"
end
function shortcuts.SwitchRoom:run(key)
    if app.room then
        local n1 = app.room
        local n2 = key == "down" and app.room + 1 or app.room - 1

        if project.rooms[n1] and project.rooms[n2] then
            if love.keyboard.isDown("lshift") then
                -- swap
                local tmp = project.rooms[n1]
                project.rooms[n1] = project.rooms[n2]
                project.rooms[n2] = tmp
            end

            app.room = n2
        end
    end
end

-- ditto
shortcuts.SwitchTool = keyboard.Shortcut:extend("SwitchTool", {input = ""})
function shortcuts.SwitchTool:onKeypressed(key)
    if self:checkModifiers() then
        for i = 1, math.min(#tools.Tool.list, 9) do
            if key == tostring(i) then
                switchTool(tools.Tool.list[i])
            end
        end
    end
end

shortcuts.MoveSelection = keyboard.Shortcut:extend("MoveSelection", {input = "", repeatable = true})
function shortcuts.MoveSelection:onKeypressed(key)
    if self:checkModifiers() then
        local dx, dy = 0, 0
        if key == "left" then dx = -1 end
        if key == "right" then dx = 1 end
        if key == "up" then dy = -1 end
        if key == "down" then dy = 1 end
        if project.selection then
            project.selection.x = project.selection.x + dx*8
            project.selection.y = project.selection.y + dy*8
        end
    end
end



return shortcuts