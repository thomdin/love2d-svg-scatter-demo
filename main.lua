require("string_util")
require("vector_util")
require("timer")
require("svg_renderer")

FPS = 30
function love.load()
    local success = love.window.setMode(640, 480, { vsync = 1, msaa = 3 })
    love.window.setTitle("Svg Scatter Demo")
    if not success then error("Failed to set window.") end
    love.graphics.setBackgroundColor(1, 1, 1)
    Scene = GhostScene()
end

function love.update(dt)
    if dt < 1 / FPS then
        love.timer.sleep(1 / FPS - dt)
    end

    Scene.update(dt)
end

function love.draw()
    Scene:draw()
end

function GhostScene()
    local renderer = SvgRenderer()
    renderer:load(love.filesystem.read("svg/ghost.svg"))
    local timer = Timer(2, function()
        Scene = ScatterScene(renderer, TreeScene())
    end)

    return {
        update = function(dt)
            timer:update(dt)
        end,
        draw = function()
            renderer:drawShapes()
        end
    }
end

function TreeScene()
    local renderer = SvgRenderer()
    renderer:load(love.filesystem.read("svg/tree.svg"))
    local timer = Timer(2, function()
        Scene = ScatterScene(renderer, GhostScene())
    end)

    return {
        update = function(dt)
            timer:update(dt)
        end,
        draw = function()
            renderer:drawShapes()
        end
    }
end

function ScatterScene(renderer, next_scene)
    local scatter_origin = { x = 100, y = 240 }
    local directions = {}
    local velocity_base = 12
    local t_to_stop = 2
    local gravity = 24
    local elapsed = 0
    for _, p in ipairs(renderer.polygons) do
        local diff = VectorUtil.substract(p.center, scatter_origin)
        local distance = VectorUtil.magnitude(diff)
        local direction = VectorUtil.normalize(diff)
        table.insert(directions, direction)
    end
    -- print(inspect(move_vectors))
    local function _movePolygon(polygon, i, dt)
        local velocity_scatter = 0
        if elapsed < t_to_stop then
            velocity_scatter = -(velocity_base / t_to_stop) * dt + velocity_base
        end
        for pi, p in ipairs(polygon.points) do
            local velocity = { x = velocity_scatter, y = velocity_scatter }
            polygon.points[pi].x = p.x + directions[i].x * velocity.x
            polygon.points[pi].y = p.y + directions[i].y * velocity.y + gravity * elapsed
        end
    end

    local timer = Timer(2.5, function()
        Scene = next_scene
    end)

    return {
        update = function(dt)
            timer:update(dt)
            elapsed = elapsed + dt
            for i, polygon in ipairs(renderer.polygons) do
                _movePolygon(polygon, i, elapsed)
            end
        end,
        draw = function()
            renderer:drawShapes()
        end
    }
end
