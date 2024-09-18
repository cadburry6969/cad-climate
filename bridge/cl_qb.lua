RegisterNetEvent('qb-weathersync:client:EnableSync', function()
    exports['cad-climate']:forceTime(GetClockHours(), GetClockMinutes(), false)
    exports['cad-climate']:forceWeather('CLEAR', false)
end)

RegisterNetEvent('qb-weathersync:client:DisableSync', function()
    exports['cad-climate']:forceTime(GetClockHours(), GetClockMinutes(), true)
    exports['cad-climate']:forceWeather('CLEAR', true)
end)
