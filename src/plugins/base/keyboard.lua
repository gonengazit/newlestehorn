local keyboard = {}



-- base static keyboard shortcut class
keyboard.Shortcut = class("Shortcut", {input = ""})

function keyboard.Shortcut:checkModifiers()
    if not self.ctrl then
        self.ctrl  = self.input:find("ctrl") and true or false
        self.shift = self.input:find("shift") and true or false
        self.alt   = self.input:find("alt") and true or false
    end

    return self.ctrl  == love.keyboard.isDown("lctrl")
    and    self.shift == love.keyboard.isDown("lshift")
    and    self.alt   == love.keyboard.isDown("lalt")
end

function keyboard.Shortcut:checkKey(key)
    if not self.key then
        self.key = self.input:match("([%g]+)$")
    end

    return key == self.key
end

function keyboard.Shortcut:keypressed(key, isrepeat)
    return self:checkModifiers() and self:checkKey(key) and (not isrepeat or self.repeatable)
end

function keyboard.Shortcut:run(key)
end



function love.keypressed(key, scancode, isrepeat)
    local x, y = love.mouse.getPosition()
    local mx, my = fromScreen(x, y)

    -- generic shortcuts
    for _, S in pairs(keyboard.Shortcut:subclasses()) do
        if S:keypressed(key, isrepeat) then
            S:run(key)
        end
    end

    -- shortcuts that work on with a nuklear window active

    if ui:keypressed(key, scancode, isrepeat) then
        return
    end

    -- shortcuts that nuklear windows swallow

    if key == "return" then
        app.enterPressed = true
    end
end

function love.keyreleased(key, scancode)
    -- just save history every time a key is released lol
    pushHistory()

    if ui:keyreleased(key, scancode) then
        return
    end
end

function love.textinput(text)
    if ui:textinput(text) then
        return
    end
end



return keyboard