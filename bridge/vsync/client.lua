---Enables sync or freezes current weather/time in response to vSync.
---@param state boolean True enables sync, false freezes current weather/time.
RegisterNetEvent('vSync:toggle', function(state)
    ---@type boolean
    local frozen = state ~= true
    exports['cad-climate']:forceTime(GetClockHours(), GetClockMinutes(), frozen)
    exports['cad-climate']:forceWeather(GlobalState.WeatherSyncing, frozen)
end)
