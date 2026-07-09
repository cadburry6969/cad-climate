if GetConvar('weather_disablecd', 'false') == 'true' then return end

---Freezes or resumes local weather/time in response to cd_easytime.
---@param toggle boolean True pauses sync (freeze), false resumes.
RegisterNetEvent('cd_easytime:PauseSync', function(toggle)
    ---@type boolean
    local frozen = toggle == true
    exports['cad-climate']:forceTime(GetClockHours(), GetClockMinutes(), frozen)
    exports['cad-climate']:forceWeather(GlobalState.WeatherSyncing, frozen)
end)
