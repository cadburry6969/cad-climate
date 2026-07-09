if GetConvar('weather_disablecd', 'false') == 'true' then return end

---Payload shape expected by cd_easytime consumers.
---@class CdWeather
---@field weather WeatherType Current synced weather.
---@field blackout boolean Current blackout state.
---@field freeze boolean Current time-freeze state.

---Exposes cad-climate state through the `cd_easytime:GetWeather` export.
AddEventHandler('__cfx_export_cd_easytime_GetWeather', function()
    ---@type CdWeather
    return {
        weather = GlobalState.WeatherSyncing,
        blackout = GlobalState.BlackoutSyncing,
        freeze = GlobalState.FreezeTimeSyncing,
    }
end)
