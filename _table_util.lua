TableUtil = {
    ifindOne = function(table, condition)
        for i, value in ipairs(table) do
            if condition(value, i) then
                return value, i
            end
        end

        return nil
    end,

    iany = function(table, condition)
        if TableUtil.ifindOne(table, condition) then
            return true
        end
        return false
    end,

    ifilter = function(t, condition)
        local res = {}
        for i, value in ipairs(t) do
            if condition(value, i) then
                table.insert(res, i)
            end
        end
        return res
    end,

    dump = function(t)
        local inspect = require("heart.vendor.inspect")
        print(inspect(t))
    end
}
