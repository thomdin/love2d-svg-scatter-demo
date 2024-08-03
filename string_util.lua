StringUtil = {
    explode = function(inputstr, sep)
        if sep == nil then
            error("sep must not be nil")
        end
        if inputstr == nil then
            error("inputstr must not be nil")
        end
        local t = {}
        for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
            table.insert(t, str)
        end
        return t
    end
}
