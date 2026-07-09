if GetResourceState('qb-core') == 'missing' and GetResourceState('qbx_core') == 'missing' then return end

---#region export binding
---Registers `func` as a `qb-weathersync` export without owning that resource name.
---@param exportName string Export name as consumers call it on `qb-weathersync`.
---@param func function Implementation backing the export.
local function exportHandler(exportName, func)
    AddEventHandler(('__cfx_export_qb-weathersync_%s'):format(exportName), function(setCB)
        setCB(func)
    end)
end
---#endregion export binding

---#region security
---Whether a source may perform a qb-weathersync mutation (console or ace holder).
---@param src integer Event source (0 = server console).
---@param ace string Ace permission required, e.g. `command.weather`.
---@return boolean allowed
local function isAllowed(src, ace)
    return src == 0 or IsPlayerAceAllowed(src, ace)
end
---#endregion security

---#region unsupported exports
exportHandler('nextWeatherStage', function()
    print('CAD-CLIMATE - THIS EXPORT IS NOT SUPPORTED (nextWeatherStage)')
end)

exportHandler('setDynamicWeather', function()
    print('CAD-CLIMATE - THIS EXPORT IS NOT SUPPORTED (setDynamicWeather)')
end)
---#endregion unsupported exports

---#region setters
---@param weather WeatherType Weather to apply globally.
exportHandler('setWeather', function(weather)
    GlobalState.WeatherSyncing = string.upper(weather)
end)

---@param hour integer New hour [0-24].
---@param minute integer New minute [0-60].
exportHandler('setTime', function(hour, minute)
    GlobalState.TimeSyncing = tonumber(hour)
    GlobalState.TimeMinutesSyncing = tonumber(minute) or 0
end)

---@param state boolean Whether the blackout is active.
exportHandler('setBlackout', function(state)
    GlobalState.BlackoutSyncing = state
end)

---@param state boolean Whether time is frozen globally.
exportHandler('setTimeFreeze', function(state)
    GlobalState.FreezeTimeSyncing = state
end)
---#endregion setters

---#region getters
---@return boolean blackout
exportHandler('getBlackoutState', function()
    return GlobalState.BlackoutSyncing
end)

---@return boolean frozen
exportHandler('getTimeFreezeState', function()
    return GlobalState.FreezeTimeSyncing
end)

---@return WeatherType weather
exportHandler('getWeatherState', function()
    return GlobalState.WeatherSyncing
end)

---@return boolean dynamic True while weather is not frozen.
exportHandler('getDynamicWeather', function()
    return not GlobalState.FreezeWeatherSyncing
end)

---@return integer hour, integer minute
exportHandler('getTime', function()
    return GlobalState.TimeSyncing, GlobalState.TimeMinutesSyncing
end)
---#endregion getters

---#region secured events
---@param weather WeatherType Weather to apply globally.
RegisterNetEvent('qb-weathersync:server:setWeather', function(weather)
    if not isAllowed(source, 'command.weather') then return end
    GlobalState.WeatherSyncing = string.upper(weather)
end)

---@param hour integer New hour [0-24].
---@param minute integer New minute [0-60].
RegisterNetEvent('qb-weathersync:server:setTime', function(hour, minute)
    if not isAllowed(source, 'command.time') then return end
    GlobalState.TimeSyncing = tonumber(hour)
    GlobalState.TimeMinutesSyncing = tonumber(minute) or 0
end)
---#endregion secured events
