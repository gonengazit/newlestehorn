local Room = require 'plugins.base.Room'

function newRoom(...)
    return Room:new(...)
end

function drawRoom(room, ...)
    room:draw(...)
end
