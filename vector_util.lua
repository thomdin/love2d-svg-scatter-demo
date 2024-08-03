VectorUtilXY = {
    magnitude = function(x, y)
        return math.sqrt(x * x + y * y)
    end,
    normalize = function(x, y)
        if x == 0 and y == 0 then return 0, 0 end
        local magnitude = VectorUtilXY.magnitude(x, y)
        return x / magnitude, y / magnitude
    end,
    substract = function(v1, v2)
        return v1.x - v2.x, v1.y - v2.y
    end,
}

VectorUtil = {
    magnitude = function(v)
        return VectorUtilXY.magnitude(v.x, v.y)
    end,
    normalize = function(v)
        local x, y = VectorUtilXY.normalize(v.x, v.y)
        return { x = x, y = y }
    end,
    substract = function(v1, v2)
        local x, y = VectorUtilXY.substract(v1, v2)
        return { x = x, y = y }
    end,
}
