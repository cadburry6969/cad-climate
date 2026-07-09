---#region variables
---Active local time freeze as `{ hour, minute }`, or nil when time syncs normally.
---@type ClimateTime?
local freezeTime = nil

---Active local weather freeze (weather held in place), or nil when weather syncs normally.
---@type WeatherType?
local freezeWeather = nil
---#endregion variables

---#region supportive functions
---@param inputstr string
---@param sep? string
---@return string[]
local function stringSplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    ---@type string[]
    local t = {}; i = 1
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

---@return nil
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
---@param hour number [0-24]
---@param time number [0-60]
---@param freeze boolean
local function forceTime(hour, time, freeze)
    freezeTime = freeze and { hour, time } or nil
    if hour and time then
        NetworkOverrideClockTime(hour, time, 0)
    end
end
exports("forceTime", forceTime)

---@param value string ['EXTRASUNNY','CLEAR','NEUTRAL','SMOG','FOGGY','OVERCAST','CLOUDS', 'CLEARING','RAIN','THUNDER','SNOW','BLIZZARD','SNOWLIGHT','XMAS','HALLOWEEN']
---@param freeze boolean
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
    ---@type WeatherType
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
    ---@type WeatherType
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
    SetWind(GetSetting('WindStrength') or 0.1)
    WaterOverrideSetStrength(GetSetting('WaterOverrideStrength') or 0.5)
    while true do
        if not freezeWeather then
            ---@type string[]
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
---@param value WeatherType New synced weather.
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

---@param value integer New synced minute [0-60].
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

---@param value boolean Whether time is now frozen globally.
AddStateBagChangeHandler('FreezeTimeSyncing', 'global', function(_, _, value)
    if value then checkTimeFreeze() end
end)

---@param value boolean Whether the artificial-lights blackout is now active.
AddStateBagChangeHandler('BlackoutSyncing', 'global', function(_, _, value)
    SetArtificialLightsState(value)
    SetArtificialLightsStateAffectsVehicles(false)
end)

AddStateBagChangeHandler('ClimateSettings', 'global', function(_, _, _)
    SetWind(GetSetting('WindStrength') or 0.1)
    WaterOverrideSetStrength(GetSetting('WaterOverrideStrength') or 0.5)
end)
---#endregion statebaghandlers

---#region zones
---A live-rendered zone: its ox_lib point and optional debug blip handle.
---@class ActiveZone
---@field point CPoint ox_lib point driving the enter/exit callbacks.
---@field blip? integer Debug radius blip handle, present only when Debug is on.

---Every zone currently registered on this client.
---@type ActiveZone[]
local activeZones = {}

---Removes all registered zones/blips and releases any zone-forced weather.
local function clearZones()
    for _, zone in ipairs(activeZones) do
        zone.point:remove()
        if zone.blip then RemoveBlip(zone.blip) end
    end
    activeZones = {}
    forceWeather(GlobalState.WeatherSyncing, false)
end

---Registers a single zone: creates its point, enter/exit handlers, and debug blip.
---@param data ClimateZone Zone definition to render.
local function registerZone(data)
    ---@type vector3
    local coords = vector3(data.coords.x, data.coords.y, data.coords.z)

    ---@type ActiveZone
    local entry = {}

    if GetSetting('Debug') then
        entry.blip = AddBlipForRadius(coords.x, coords.y, coords.z, data.radius)
        SetBlipColour(entry.blip, 1)
        SetBlipAlpha(entry.blip, 155)
    end

    ---@type CPoint
    local point = lib.points.new({
        coords = coords,
        distance = data.radius,
    })

    function point:onEnter()
        forceWeather(data.weather, true)
        if data.time then
            forceTime(data.time[1], data.time[2], true)
        end
    end

    function point:onExit()
        forceWeather(data.weather, false)
        if data.time then
            forceTime(data.time[1], data.time[2], false)
        end
    end

    entry.point = point
    activeZones[#activeZones + 1] = entry
end

---Clears and re-registers every zone from the shared `ClimateZones` state.
local function renderZones()
    clearZones()
    for _, data in pairs(GlobalState.ClimateZones or {}) do
        registerZone(data)
    end
end

CreateThread(function()
    while GlobalState.ClimateZones == nil do Wait(100) end
    renderZones()
end)

AddStateBagChangeHandler('ClimateZones', 'global', function(_, _, _)
    renderZones()
end)
---#endregion zones
