---#region variables
local freezeTime = nil
local freezeWeather = nil
---#endregion variables

---#region supportive functions
local function stringSplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}; i = 1
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

local function checkTimeFreeze()
    CreateThread(function()
        while GlobalState.FreezeTimeSyncing do
            Wait(3000)
            NetworkOverrideClockTime(GlobalState.TimeSyncing, GlobalState.TimeMinutesSyncing, 0)
        end
    end)
end
---#endregion supportive functions

---#region exports
---@param freeze boolean
---@param hour number [0-24]
---@param time number [0-60]
local function forceTime(hour, time, freeze)
    freezeTime = freeze and { hour, time } or nil
    if hour and time then
        NetworkOverrideClockTime(hour, time, 0)
    end
end
exports("forceTime", forceTime)

---@param freeze boolean
---@param value string ['EXTRASUNNY','CLEAR','NEUTRAL','SMOG','FOGGY','OVERCAST','CLOUDS', 'CLEARING','RAIN','THUNDER','SNOW','BLIZZARD','SNOWLIGHT','XMAS','HALLOWEEN']
local function forceWeather(value, freeze)
    freezeWeather = freeze and value or nil
    if value then
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        SetWeatherTypeNowPersist(value)
        SetWeatherTypeNow(value)
        SetWeatherTypeNowPersist(value)

        if value == 'XMAS' then
            SetForceVehicleTrails(true)
            SetForcePedFootstepsTracks(true)
        else
            SetForceVehicleTrails(false)
            SetForcePedFootstepsTracks(false)
        end
    end
end
exports("forceWeather", forceWeather)
---#endregion exports

---#region init initial values
AddEventHandler('playerSpawned', function()
    local weather = GlobalState.WeatherSyncing
    SetWeatherOwnedByNetwork(false)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypeNowPersist(weather)

    if weather == 'XMAS' then
        SetForceVehicleTrails(true)
        SetForcePedFootstepsTracks(true)
    else
        SetForceVehicleTrails(false)
        SetForcePedFootstepsTracks(false)
    end
    NetworkOverrideClockTime(GlobalState.TimeSyncing, GlobalState.TimeMinutesSyncing, 0)
    checkTimeFreeze()
end)

AddEventHandler("onResourceStart", function(name)
    if name ~= GetCurrentResourceName() then
        return
    end
    local weather = GlobalState.WeatherSyncing
    SetWeatherOwnedByNetwork(false)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypeNowPersist(weather)

    if weather == 'XMAS' then
        SetForceVehicleTrails(true)
        SetForcePedFootstepsTracks(true)
    else
        SetForceVehicleTrails(false)
        SetForcePedFootstepsTracks(false)
    end
    NetworkOverrideClockTime(GlobalState.TimeSyncing, GlobalState.TimeMinutesSyncing, 0)
    checkTimeFreeze()
end)

CreateThread(function()
    SetWind(WindStrength or 0.1)
    WaterOverrideSetStrength(WaterOverrideStrength or 0.5)
    while true do
        if not freezeWeather then
            local tWeather = stringSplit(GetWeatherTypeTransition(), " ")
            if tWeather[1] ~= GetHashKey(GlobalState.WeatherSyncing) then
                ClearOverrideWeather()
                ClearWeatherTypePersist()
                SetWeatherTypePersist(GlobalState.WeatherSyncing)
                SetWeatherTypeNow(GlobalState.WeatherSyncing)
                SetWeatherTypeNowPersist(GlobalState.WeatherSyncing)
            end
        end
        Wait(15 * 1000)
    end
end)
---#endregion init initial values

---#region statebaghandlers
AddStateBagChangeHandler('WeatherSyncing', 'global', function(_, _, value)
    if not freezeWeather then
        SetWeatherTypeOverTime(value, 15.0)
        Wait(15000)
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        SetWeatherTypePersist(value)
        SetWeatherTypeNow(value)
        SetWeatherTypeNowPersist(value)

        if value == 'XMAS' then
            SetForceVehicleTrails(true)
            SetForcePedFootstepsTracks(true)
        else
            SetForceVehicleTrails(false)
            SetForcePedFootstepsTracks(false)
        end
    end
end)

AddStateBagChangeHandler('TimeMinutesSyncing', 'global', function(_, _, value)
    if freezeTime then
        NetworkOverrideClockTime(freezeTime[1], freezeTime[2], 0)
        return
    end
    if GlobalState.FreezeTimeSyncing then
        return
    end
    NetworkOverrideClockTime(GlobalState.TimeSyncing, value, 0)
end)

AddStateBagChangeHandler('FreezeTimeSyncing', 'global', function(_, _, value)
    if value then checkTimeFreeze() end
end)

AddStateBagChangeHandler('BlackoutSyncing', 'global', function(_, _, value)
    SetArtificialLightsState(value)
    SetArtificialLightsStateAffectsVehicles(false)
end)
---#endregion statebaghandlers

---#region zones
CreateThread(function()
    for _, data in pairs(WeatherZones) do
        if Debug then
            local _blip = AddBlipForRadius(data.coords.x, data.coords.y, data.coords.z, data.radius)
            SetBlipColour(_blip, 1)
            SetBlipAlpha(_blip, 155)
        end
        local _point = lib.points.new({
            coords = data.coords,
            distance = data.radius,
        })

        function _point:onEnter()
            forceWeather(data.weather, true)
        end

        function _point:onExit()
            forceWeather(data.weather, false)
        end
    end
end)
---#endregion zones
