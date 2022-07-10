local Room = class("Room")



function Room:init(x, y, w, h)
    self.x = x or 0
    self.y = y or 0
    self.w = w or 16
    self.h = h or 16
    self.hex = true
    self.data = fill2d0s(self.w, self.h)
    self.exits = {left = false, bottom = false, right = false, top = true}
    self.params = {}
    self.title = ""
    self.camtriggers = {} 
end



return Room