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

function keyboard.Shortcut:onKeypressed(key, isrepeat)
    if self:checkModifiers() and self:checkKey(key) and (not isrepeat or self.repeatable) then
        self:run(key)
    end
end

function keyboard.Shortcut:run(key)
end

function keyboard.Shortcut:keypressed(key, isrepeat)
    for _, S in pairs(self:subclasses()) do
        S:onKeypressed(key, isrepeat)
    end
end



function love.keypressed(key, scancode, isrepeat)
    local x, y = love.mouse.getPosition()
    local mx, my = app:fromScreen(x, y)

    -- generic shortcuts
    keyboard.Shortcut:keypressed(key, isrepeat)

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