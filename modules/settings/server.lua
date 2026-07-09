---#region persistence
---Name of this resource, used for every LoadResourceFile/SaveResourceFile call.
---@type string
local resource = GetCurrentResourceName()

---Path (relative to the resource) of the config file we rewrite.
---@type string
local CONFIG_FILE = 'config.lua'

---Rewrites a single scalar `key = value` assignment inside `config.lua`.
---@param key ClimateSettingKey Config key to replace.
---@param value boolean|number New value to write.
---@return boolean saved True if the key was found and the file written.
local function saveToConfig(key, value)
    ---@type string?
    local content = LoadResourceFile(resource, CONFIG_FILE)
    if not content then return false end

    ---@type string
    local literal = tostring(value)
    ---@type string
    local pattern = ('(%s%%s*=%%s*)[^,\n]*'):format(key)
    local updated, count = content:gsub(pattern, '%1' .. literal, 1)
    if count == 0 then return false end

    SaveResourceFile(resource, CONFIG_FILE, updated, -1)
    return true
end

---Serialises one zone to a `config.lua` table entry line.
---@param zone ClimateZone Zone to serialise.
---@return string line Lua source for the zone, indented for the config block.
local function zoneToLiteral(zone)
    ---@type string
    local timeStr = ''
    if zone.time then
        timeStr = (' time = { %d, %d },'):format(zone.time[1], zone.time[2])
    end
    return ("        { name = '%s', coords = vector3(%.2f, %.2f, %.2f), radius = %.1f, weather = '%s',%s dynamic = %s },")
        :format(zone.name, zone.coords.x, zone.coords.y, zone.coords.z, zone.radius, zone.weather, timeStr, tostring(zone.dynamic))
end

---Rewrites the whole `WeatherZones = { ... }` block in `config.lua`.
---@param zones ClimateZone[] Full zone list to persist.
---@return boolean saved True if the block was found and the file written.
local function writeZonesToConfig(zones)
    ---@type string?
    local content = LoadResourceFile(resource, CONFIG_FILE)
    if not content then return false end

    ---@type string[]
    local lines = {
        '    -- { name: string, coords: vec3, radius: float, weather: string, time: array[hour, min], dynamic: boolean },',
        '    WeatherZones = {',
    }
    for _, zone in ipairs(zones) do
        lines[#lines + 1] = zoneToLiteral(zone)
    end
    lines[#lines + 1] = '    },'

    ---@type string
    local block = (table.concat(lines, '\n')):gsub('%%', '%%%%')
    local updated, count = content:gsub('[ ]*%-%-[^\n]*\n    WeatherZones%s*=%s*{.-\n    },', block, 1)
    if count == 0 then
        updated, count = content:gsub('    WeatherZones%s*=%s*{.-\n    },', block, 1)
        if count == 0 then return false end
    end

    SaveResourceFile(resource, CONFIG_FILE, updated, -1)
    return true
end
---#endregion persistence

---#region security
---Whether a source is allowed to mutate climate config (console or admin ace).
---@param source integer Event source (0 = server console).
---@return boolean allowed
local function isAdmin(source)
    return source == 0 or IsPlayerAceAllowed(source, 'command')
end
---#endregion security

---#region init
---Builds the runtime zone list from the config, normalising coords to plain tables.
---@return ClimateZone[] zones
local function seedZones()
    ---@type ClimateZone[]
    local zones = {}
    for i, zone in ipairs(Config.WeatherZones) do
        zones[i] = {
            name = zone.name or ('Zone %d'):format(i),
            coords = { x = zone.coords.x + 0.0, y = zone.coords.y + 0.0, z = zone.coords.z + 0.0 },
            radius = zone.radius + 0.0,
            weather = zone.weather,
            time = zone.time,
            dynamic = zone.dynamic == true,
        }
    end
    return zones
end

---@type ClimateZone[]
local runtimeZones = seedZones()

CreateThread(function()
    GlobalState.ClimateSettings = {}
    GlobalState.ClimateZones = runtimeZones
end)
---#endregion init

---#region events
---Validates and normalises a client-supplied `{ hour, minute }` pair.
---@param raw any Untrusted value from the client.
---@return ClimateTime|nil time Normalised time, or nil when not set/invalid.
local function parseTime(raw)
    if type(raw) ~= 'table' then return nil end
    ---@type number?
    local hour = tonumber(raw[1])
    if not hour then return nil end
    ---@type number
    local minute = tonumber(raw[2]) or 0
    return { math.floor(hour) % 24, math.floor(minute) % 60 }
end

---Overrides a single scalar config value; admin only.
---@param key ClimateSettingKey
---@param value boolean|number
RegisterNetEvent('climate:setConfig', function(key, value)
    ---@type integer
    local src = source
    if not isAdmin(src) then return end

    ---@type boolean|number|nil
    local default = GetSettingDefaults()[key]
    if default == nil then return end

    if type(default) == 'boolean' then
        if type(value) ~= 'boolean' then return end
    elseif type(default) == 'number' then
        value = tonumber(value)
        if not value then return end
        if math.type(default) == 'integer' then value = math.floor(value) end
    else
        return
    end

    if not saveToConfig(key, value) then return end

    ---@type table<ClimateSettingKey, boolean|number>
    local overrides = GlobalState.ClimateSettings or {}
    overrides[key] = value
    GlobalState.ClimateSettings = overrides
end)

---Creates a new weather zone at the given coords; admin only.
---@param data { name: string, coords: { x: number, y: number, z: number }, radius: number, weather: string, time?: ClimateTime, dynamic: boolean }
RegisterNetEvent('climate:addZone', function(data)
    if not isAdmin(source) then return end
    if type(data) ~= 'table' or type(data.coords) ~= 'table' then return end

    ---@type string
    local weather = string.upper(tostring(data.weather or ''))
    ---@type boolean
    local valid = false
    for _, wtype in ipairs(Config.WeatherTypes) do
        if wtype == weather then valid = true break end
    end
    if not valid then return end

    ---@type number?
    local radius = tonumber(data.radius)
    if not radius or radius <= 0 then return end

    ---@type ClimateZone
    local zone = {
        name = tostring(data.name or 'New Zone'),
        coords = { x = data.coords.x + 0.0, y = data.coords.y + 0.0, z = data.coords.z + 0.0 },
        radius = radius,
        weather = weather,
        time = parseTime(data.time),
        dynamic = data.dynamic == true,
    }

    runtimeZones[#runtimeZones + 1] = zone
    if not writeZonesToConfig(runtimeZones) then
        runtimeZones[#runtimeZones] = nil
        return
    end
    GlobalState.ClimateZones = runtimeZones
end)

---Updates an existing weather zone by its 1-based index; admin only.
---@param index integer Index into the runtime zone list.
---@param data { name?: string, radius?: number, weather?: string, time?: ClimateTime, dynamic?: boolean }
RegisterNetEvent('climate:editZone', function(index, data)
    if not isAdmin(source) then return end
    index = tonumber(index)
    if not index then return end

    ---@type ClimateZone?
    local zone = runtimeZones[index]
    if not zone or type(data) ~= 'table' then return end

    ---@type string
    local weather = string.upper(tostring(data.weather or zone.weather))
    ---@type boolean
    local valid = false
    for _, wtype in ipairs(Config.WeatherTypes) do
        if wtype == weather then valid = true break end
    end
    if not valid then return end

    ---@type number
    local radius = tonumber(data.radius) or zone.radius
    if radius <= 0 then return end

    zone.name = tostring(data.name or zone.name)
    zone.weather = weather
    zone.radius = radius
    zone.time = parseTime(data.time)
    zone.dynamic = data.dynamic == true

    if not writeZonesToConfig(runtimeZones) then return end
    GlobalState.ClimateZones = runtimeZones
end)

---Restores every scalar setting to its server-start value; admin only.
RegisterNetEvent('climate:resetConfig', function()
    if not isAdmin(source) then return end
    for key, value in pairs(GetSettingDefaults()) do
        saveToConfig(key, value)
    end
    GlobalState.ClimateSettings = {}
end)
---#endregion events

---#region command
---Opens the climate config menu for the invoking admin.
---@param source integer Player who ran the command.
---@param args string[] Raw positional arguments (unused).
---@param raw string Full raw command string (unused).
lib.addCommand('climate_config', {
    help = 'Open the climate config menu',
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent('climate:openConfigMenu', source)
end)
---#endregion command
