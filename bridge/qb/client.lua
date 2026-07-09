if GetResourceState('qb-core') == 'missing' and GetResourceState('qbx_core') == 'missing' then return end

---Resumes syncing to the global weather/time.
RegisterNetEvent('qb-weathersync:client:EnableSync', function()
    exports['cad-climate']:forceTime(GetClockHours(), GetClockMinutes(), false)
    exports['cad-climate']:forceWeather(GlobalState.WeatherSyncing, false)
end)

---Freezes local weather/time (clear weather) until re-enabled.
RegisterNetEvent('qb-weathersync:client:DisableSync', function()
    exports['cad-climate']:forceTime(GetClockHours(), GetClockMinutes(), true)
    exports['cad-climate']:forceWeather('CLEAR', true)
end)

---Re-syncs to the global weather/time once the player has loaded in.
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    exports['cad-climate']:forceTime(GetClockHours(), GetClockMinutes(), false)
    exports['cad-climate']:forceWeather(GlobalState.WeatherSyncing, false)
end)
