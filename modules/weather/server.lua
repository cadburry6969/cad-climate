---#region declares
---Cached `string.upper` for the weather-name comparisons in the hot path.
---@type fun(s: string): string
local string_upper = string.upper

---Toggle state for the `/freeze_weather` command.
---@type boolean?
FrozenWeather = FrozenWeather

---Toggle state for the `/freeze_time` command.
---@type boolean?
FrozenTime = FrozenTime
---#endregion declares

---#region supportive functions
---@param name string
---@return boolean
local function doesWeatherExist(name)
    for _, wtype in ipairs(Config.WeatherTypes) do
        if string_upper(name) == string_upper(wtype) then
            return true
        end
    end
    return false
end

---@return nil
local function cycleWeather()
    if not GlobalState.FreezeWeatherSyncing and not GetSetting('ForceXMAS') then
        GlobalState.WeatherSyncing = Config.DynamicWeatherList[math.random(#Config.DynamicWeatherList)]
    end
    if GetSetting('ForceXMAS') then
        GlobalState.WeatherSyncing = 'XMAS'
    end
end
---#endregion supportive functions

---#region override events
---@param name string
---@param freeze boolean
RegisterNetEvent('climate:changeWeather', function(name, freeze)
    if doesWeatherExist(name) then
        GlobalState.WeatherSyncing = string_upper(name)
    end
    GlobalState.FreezeWeatherSyncing = freeze or false
end)

---@param hour number
---@param min number
---@param freeze boolean
RegisterNetEvent('climate:changeTime', function(hour, min, freeze)
    if hour and min then
        if tonumber(hour) <= 24 and tonumber(min) <= 60 then
            GlobalState.TimeSyncing = tonumber(hour)
            GlobalState.TimeMinutesSyncing = tonumber(min)
            GlobalState.TimeMinutesSyncing = GlobalState.TimeMinutesSyncing + 1
        end
    end
    GlobalState.FreezeTimeSyncing = freeze or false
end)
---#endregion override events

---#region init values and updates them
CreateThread(function()
    GlobalState.WeatherSyncing = 'EXTRASUNNY'
    GlobalState.TimeSyncing = 12
    GlobalState.TimeMinutesSyncing = 0
    GlobalState.FreezeTimeSyncing = false
    GlobalState.FreezeWeatherSyncing = false
    GlobalState.BlackoutSyncing = false
    if GetSetting('ForceXMAS') then
        GlobalState.WeatherSyncing = 'XMAS'
    end
end)

CreateThread(function()
    while true do
        Wait(GetSetting('DynamicTimeChanger'))
        if not GlobalState.FreezeTimeSyncing then
            GlobalState.TimeMinutesSyncing = GlobalState.TimeMinutesSyncing + 1
            if GlobalState.TimeSyncing < 6 or GlobalState.TimeSyncing > 22 then
                GlobalState.TimeMinutesSyncing = GlobalState.TimeMinutesSyncing + 2
            end
            if GlobalState.TimeMinutesSyncing >= 60 then
                if GlobalState.TimeSyncing < 24 then
                    GlobalState.TimeSyncing = GlobalState.TimeSyncing + 1
                    if math.random(8) == 2 then
                        cycleWeather()
                    end
                elseif GlobalState.TimeSyncing == 24 then
                    GlobalState.TimeSyncing = 0
                end
                GlobalState.TimeMinutesSyncing = 0
            end
        end
    end
end)
---#endregion init values and updates them

---#region commands
lib.addCommand('freeze_weather', {
    help = 'Freeze weather globally',
    restricted = 'group.admin'
}, function(source, args, raw)
    if FrozenWeather then
        FrozenWeather = false
        GlobalState.FreezeWeatherSyncing = false
        print('Dynamic weather on!')
    else
        FrozenWeather = true
        GlobalState.FreezeWeatherSyncing = true
        print('Dynamic weather off!')
    end
end)

lib.addCommand('freeze_time', {
    help = 'Freeze time globally',
    restricted = 'group.admin'
}, function(source, args, raw)
    if FrozenTime then
        FrozenTime = false
        GlobalState.FreezeTimeSyncing = false
        print('Dynamic time on!')
    else
        FrozenTime = true
        GlobalState.FreezeTimeSyncing = true
        print('Dynamic time off!')
    end
end)

lib.addCommand('weather', {
    help = 'Change weather globally',
    params = {
        {
            name = 'name',
            type = 'string',
            help = table.concat(Config.WeatherTypes, ', '),
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    ---@type string?
    local weather = args['name']
    if weather then
        if doesWeatherExist(weather) then
            GlobalState.WeatherSyncing = string_upper(weather)
            print('Weather is now: ' .. GlobalState.WeatherSyncing)
        else
            print('Weather type not in table')
        end
    else
        print('Enter in a type (Ex: /weather EXTRASUNNY)')
    end
end)

lib.addCommand('time', {
    help = 'Change time globally',
    params = {
        {
            name = 'hour',
            type = 'number',
            help = 'Hour',
        },
        {
            name = 'min',
            type = 'number',
            help = 'Minute',
        },
    },
    restricted = 'group.admin'
}, function(source, args, raw)
    ---@type number?
    local hour = args['hour']
    ---@type number?
    local min = args['min']
    if hour and min then
        if tonumber(hour) <= 24 and tonumber(min) <= 60 then
            GlobalState.TimeSyncing = tonumber(hour)
            GlobalState.TimeMinutesSyncing = tonumber(min)
            print('Time is now: ' .. GlobalState.TimeSyncing .. ' ' .. GlobalState.TimeMinutesSyncing)
            GlobalState.TimeMinutesSyncing = GlobalState.TimeMinutesSyncing + 1
        else
            print('Wrong format (/time 12)')
        end
    else
        print('Wrong format (/time 12 0)')
    end
end)

lib.addCommand('blackout', {
    help = 'Change blackout status',
    restricted = 'group.admin'
}, function(source, args, raw)
    if GlobalState.BlackoutSyncing then
        GlobalState.BlackoutSyncing = false
        print('Blackout off!')
    else
        GlobalState.BlackoutSyncing = true
        print('Blackout on!')
    end
end)

lib.addCommand('current_climate', {
    help = 'Get current weather list',
    restricted = 'group.admin'
}, function(source, args, raw)
    print('Current Sync: ' ..
        GlobalState.WeatherSyncing .. ' ' .. GlobalState.TimeSyncing .. ':' .. GlobalState.TimeMinutesSyncing)
end)
---#endregion commands
