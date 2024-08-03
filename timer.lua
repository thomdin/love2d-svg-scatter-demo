function Timer(time, callback, loop)
    local loopUpdate = function(self, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed >= time then
            callback()
            self.elapsed = 0
        end
    end
    local oneTimeUpdate = function(self, dt)
        if self.fired then return end
        self.elapsed = self.elapsed + dt
        if self.elapsed >= time then
            callback()
            self.fired = true
        end
    end
    return {
        loop = loop,
        elapsed = 0,
        fired = false,
        pause = false,
        stop = function(self)
            self.pause = true
        end,
        start = function(self)
            self.pause = false
        end,
        reset = function(self)
            self.elapsed = 0
            self.fired = false
        end,
        update = function(self, dt)
            if self.pause then return end
            if self.loop then
                loopUpdate(self, dt)
            else
                oneTimeUpdate(self, dt)
            end
        end
    }
end
