SvgRenderer = function(self)
    local xmlparser = require("xmlparser")
    self = {
        raw_svg = '',
        polygons = {},
        lookup_t = {},
    }

    local function _index(t, prev_point)
        local id = nil
        if t.attrs then
            id = t.attrs.id
        end

        local function _coordsFromString(str)
            local coords = StringUtil.explode(str, ',')
            if #coords ~= 2 then error("Could not parse coordinates in path id " .. t.attrs.id) end
            local x, y = tonumber(coords[1]), tonumber(coords[2])
            if x == nil or y == nil then
                error("Could not parse coordinates in path. id " ..
                    t.attrs.id .. " Failed to convert number.")
            end
            return x, y
        end

        local function _polygon_add_point(polygon, xy, prev)
            table.insert(polygon.points, xy)
            prev.x = xy.x
            prev.y = xy.y
        end

        local function _parseHexColor(color)
            if color == "none" then return nil end
            local color_hex = string.sub(color, 2, #color)
            local rgb = {}
            for i = 1, #color_hex, 2 do
                local n = string.sub(color_hex, i, i + 1)
                local d = tonumber("0x" .. n)
                table.insert(rgb, d)
            end
            local _r, _g, _b = love.math.colorFromBytes(unpack(rgb))
            return { _r, _g, _b }
        end

        local function _parse_style_attr(str, polygon)
            local defs = StringUtil.explode(str, ";")
            local styles = {}
            for _, s in ipairs(defs) do
                local t = StringUtil.explode(s, ":")
                if #t ~= 2 then error("Invalid style " .. s) end
                styles[t[1]] = t[2]
            end
            if styles["fill"] then
                polygon.fill = _parseHexColor(styles["fill"])
            end
            if styles["stroke"] then
                polygon.stroke = _parseHexColor(styles["stroke"])
            end
            if styles["stroke-width"] then
                polygon.stroke_w = tonumber(styles["stroke-width"])
            else
                polygon.stroke_w = 1
            end
        end

        if t.tag then
            if string.lower(t.tag) == "rect" then
                -- Rectangle
                if not t.attrs.width or not t.attrs.height or not t.attrs.x or not t.attrs.y then
                    error("Element id " .. t.attrs.id .. ": Rectangle must have width, height, x, y attributes")
                end
                local x, y, w, h = tonumber(t.attrs.x),
                    tonumber(t.attrs.y),
                    tonumber(t.attrs.width),
                    tonumber(t.attrs.height)
                if not x or not y or not w or not y then
                    error("Invalid attributes in rectangle id " .. t.attrs.id)
                end
                local rect = {
                    points = { { x = x, y = y }, { x = x + w, y = y },
                        { x = x + w, y = y + h }, { x = x, y = y + h } },
                    w = w,
                    h = h,
                }

                if t.attrs.style then
                    _parse_style_attr(t.attrs.style, rect)
                end
                table.insert(self.polygons, rect)
                self.lookup_t[t.attrs.id] = rect

                -- Path
            elseif string.lower(t.tag) == "path" then
                if not t.attrs.d then error("Invalid path element id " .. t.attrs.id .. ", d is missing.") end
                local instructions = StringUtil.explode(t.attrs.d, " ")
                if #instructions <= 2 then
                    error("Failed to parse path element id " ..
                        t.attrs.id .. ". not enough instructions.")
                end

                local mode = "M"
                local first_point = { x = 0, y = 0 }
                local polygon = { points = {}, w = 0, h = 0, fill = { 1, 1, 1 }, svg_id = t.attrs.id }
                if instructions[1] == "M" then
                    mode = "M"
                elseif instructions[1] == "m" then
                    mode = "m"
                else
                    error("First instruction must be M or m - Path id " .. t.attrs.id)
                end
                local x, y = _coordsFromString(instructions[2])
                first_point = { x = x, y = y }
                _polygon_add_point(polygon, first_point, prev_point)

                local last_point = { x = first_point.x, y = first_point.y }

                local i = 2
                while true do
                    i = i + 1
                    local val = instructions[i]
                    if not val then break end
                    if val == "Z" or val == "z" then break end

                    if val == "V" then
                        mode = "M"
                        local point = { x = prev_point.x, y = prev_point.y + tonumber(instructions[i + 1]) }
                        _polygon_add_point(polygon, point, prev_point)
                        i = i + 1
                    elseif val == "L" then
                        mode = "M"
                        local x, y = _coordsFromString(instructions[i + 1])
                        _polygon_add_point(polygon, { x = x, y = y }, prev_point)
                        i = i + 1
                    elseif val == "l" then
                        mode = "m"
                        local dx, dy = _coordsFromString(instructions[i + 1])
                        _polygon_add_point(polygon, { x = prev_point.x + dx, y = prev_point.y + dy }, prev_point)
                        i = i + 1
                    elseif val == "v" then
                        local dy = tonumber(instructions[i + 1])
                        _polygon_add_point(polygon, { x = prev_point.x, y = prev_point.y + dy }, prev_point)
                        i = i + 1
                    elseif val == "h" then
                        local dx = tonumber(instructions[i + 1])
                        _polygon_add_point(polygon, { x = prev_point.x + dx, y = prev_point.y }, prev_point)
                        i = i + 1
                    else
                        local x, y = _coordsFromString(val)
                        if mode == "m" then
                            _polygon_add_point(polygon, { x = prev_point.x + x, y = prev_point.y + y }, prev_point)
                        else
                            _polygon_add_point(polygon, { x = x, y = y }, prev_point)
                        end
                    end
                end
                if t.attrs.style then
                    _parse_style_attr(t.attrs.style, polygon)
                end
                local min_x, max_x, min_y, max_y = math.huge, -math.huge, math.huge, -math.huge
                for _, p in ipairs(polygon.points) do
                    if p.x < min_x then min_x = p.x end
                    if p.x > max_x then max_x = p.x end
                    if p.y < min_y then min_y = p.y end
                    if p.y > max_y then max_y = p.y end
                end
                polygon.w, polygon.h = (max_x - min_x), (max_y - min_y)
                polygon.min_x, polygon.max_x = min_x, max_x
                polygon.min_y, polygon.max_y = min_y, max_y
                polygon.center = {
                    x = min_x + polygon.w / 2,
                    y = min_y + polygon.h / 2,
                }
                table.insert(self.polygons, polygon)
                self.lookup_t[t.attrs.id] = polygon
            end
        end

        if not t.children then
            return
        end
        for _, c in ipairs(t.children) do
            _index(c, prev_point)
        end
    end

    local function _pointQueue(polygon)
        local q = {}
        for _, p in ipairs(polygon.points) do
            table.insert(q, p.x)
            table.insert(q, p.y)
        end
        return q
    end

    self.drawById   = function(self, id)
        if not self.lookup_t[id] then error("id is not in lookup table.") end
        if not self.lookup_t[id].points then error("Element has no points.") end
        local polygon = self.lookup_t[id]
        love.graphics.setColor(unpack(polygon.fill))
        love.graphics.polygon("fill", unpack(_pointQueue(polygon)))
    end

    self.drawShapes = function(self)
        for _, p in ipairs(self.polygons) do
            if p.fill then
                love.graphics.setColor(p.fill)
                love.graphics.polygon("fill", unpack(_pointQueue(p)))
            elseif p.stroke then
                love.graphics.push()
                love.graphics.setLineWidth(p.stroke_w)
                love.graphics.setColor(p.stroke)
                love.graphics.polygon("line", unpack(_pointQueue(p)))
                love.graphics.pop()
            end
        end
    end

    self.load       = function(self, s)
        if not s then error("No string content given.") end
        if s == "" then error("Empty string is not allowed.") end
        self.raw_svg = s
        local data = xmlparser.parse(s)

        _index(data, { x = 0, y = 0 })
    end

    return self
end
