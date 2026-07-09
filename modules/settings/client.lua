---#region helpers
---Returns the overridable setting keys in a stable alphabetical order.
---@return ClimateSettingKey[] keys
local function sortedKeys()
    ---@type ClimateSettingKey[]
    local keys = {}
    for key in pairs(GetSettingDefaults()) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

---Builds the weather dropdown options from the configured weather types.
---@return { value: WeatherType, label: WeatherType }[] options
local function weatherOptions()
    ---@type { value: WeatherType, label: WeatherType }[]
    local options = {}
    for i, weather in ipairs(Config.WeatherTypes) do
        options[i] = { value = weather, label = weather }
    end
    return options
end
---#endregion helpers

---Forward declaration so the dialogs can reopen the menu.
---@type fun()
local openConfigMenu

---#region zone dialog
---Prompts for a new zone and sends it to the server, using the player's coords.
local function addZoneDialog()
    ---@type (string|number|boolean)[]?
    local input = lib.inputDialog('Add Weather Zone', {
        { type = 'input',    label = 'Name',        default = 'New Zone', required = true },
        { type = 'number',   label = 'Radius',      default = 100.0, min = 1.0, required = true },
        { type = 'select',   label = 'Weather',     options = weatherOptions(), required = true },
        { type = 'number',   label = 'Hour',        description = 'Optional forced time', min = 0, max = 24 },
        { type = 'number',   label = 'Minute',      min = 0, max = 59 },
        { type = 'checkbox', label = 'Dynamic' },
    })

    if input then
        ---@type vector3
        local coords = GetEntityCoords(cache.ped)
        TriggerServerEvent('climate:addZone', {
            name = input[1],
            coords = { x = coords.x, y = coords.y, z = coords.z },
            radius = input[2] + 0.0,
            weather = input[3],
            time = input[4] and { input[4], input[5] or 0 } or nil,
            dynamic = input[6] == true,
        })
    end

    Wait(200)
    openConfigMenu()
end

---Prompts to edit an existing zone and sends the changes to the server.
---@param index integer 1-based index of the zone in the shared list.
---@param zone ClimateZone Current zone values used to pre-fill the dialog.
local function editZoneDialog(index, zone)
    ---@type (string|number|boolean)[]?
    local input = lib.inputDialog(('Edit %s'):format(zone.name), {
        { type = 'input',    label = 'Name',        default = zone.name, required = true },
        { type = 'number',   label = 'Radius',      default = zone.radius, min = 1.0, required = true },
        { type = 'select',   label = 'Weather',     options = weatherOptions(), default = zone.weather, required = true },
        { type = 'number',   label = 'Hour',        description = 'Optional forced time', default = zone.time and zone.time[1] or nil, min = 0, max = 24 },
        { type = 'number',   label = 'Minute',      default = zone.time and zone.time[2] or nil, min = 0, max = 59 },
        { type = 'checkbox', label = 'Dynamic',     checked = zone.dynamic },
    })

    if input then
        TriggerServerEvent('climate:editZone', index, {
            name = input[1],
            radius = input[2] + 0.0,
            weather = input[3],
            time = input[4] and { input[4], input[5] or 0 } or nil,
            dynamic = input[6] == true,
        })
    end

    Wait(200)
    openConfigMenu()
end

---Lists every active zone and opens the edit dialog for the chosen one.
local function editZonesMenu()
    ---@type ClimateZone[]
    local zones = GlobalState.ClimateZones or {}
    if #zones == 0 then
        lib.notify({ description = 'No weather zones to edit', type = 'error' })
        return openConfigMenu()
    end

    ---@type MenuOptions[]
    local options = {}
    for i, zone in ipairs(zones) do
        ---@type string
        local timeStr = zone.time and ('%02d:%02d'):format(zone.time[1], zone.time[2]) or 'off'
        options[i] = {
            label = zone.name,
            description = ('%s | Radius %.1f | Time %s | Dynamic: %s'):format(zone.weather, zone.radius, timeStr, tostring(zone.dynamic)),
        }
    end

    lib.registerMenu({
        id = 'climate_zones_menu',
        title = 'Edit Weather Zones',
        position = 'top-right',
        options = options,
    }, function(selected)
        editZoneDialog(selected, zones[selected])
    end)

    lib.showMenu('climate_zones_menu')
end
---#endregion zone dialog

---#region menu
---Builds and shows the main climate config menu.
function openConfigMenu()
    ---@type ClimateSettings
    local defaults = GetSettingDefaults()
    ---@type ClimateSettingKey[]
    local keys = sortedKeys()
    ---@type integer
    local zoneIndex = #keys + 1
    ---@type integer
    local editZoneIndex = #keys + 2
    ---@type integer
    local resetIndex = #keys + 3

    ---@type MenuOptions[]
    local options = {}
    for i, key in ipairs(keys) do
        ---@type boolean|number|nil
        local value = GetSetting(key)
        if type(defaults[key]) == 'boolean' then
            options[i] = { label = key, checked = value --[[@as boolean]] }
        else
            options[i] = { label = key, description = ('Current: %s'):format(tostring(value)) }
        end
    end
    options[zoneIndex] = { label = 'Add weather zone', description = 'Create a zone at your position' }
    options[editZoneIndex] = { label = 'Edit weather zones', description = 'Modify an existing zone' }
    options[resetIndex] = { label = 'Reset config', description = 'Restore the values from server start' }

    lib.registerMenu({
        id = 'climate_config_menu',
        title = 'Climate Config',
        position = 'top-right',
        ---Toggles a boolean setting when its checkbox is flipped.
        ---@param selected integer Index of the checkbox option.
        ---@param checked boolean New checkbox state.
        onCheck = function(selected, checked)
            TriggerServerEvent('climate:setConfig', keys[selected], checked)
        end,
        options = options,
    }, ---@param selected integer Index of the chosen option.
    function(selected)
        if selected == zoneIndex then
            addZoneDialog()
            return
        end

        if selected == editZoneIndex then
            editZonesMenu()
            return
        end

        if selected == resetIndex then
            TriggerServerEvent('climate:resetConfig')
            Wait(200)
            openConfigMenu()
            return
        end

        ---@type ClimateSettingKey
        local key = keys[selected]
        ---@type (string|number|boolean)[]?
        local input = lib.inputDialog(('Set %s'):format(key), {
            { type = 'number', label = key, default = GetSetting(key) --[[@as number]], required = true },
        })
        if input and input[1] ~= nil then
            TriggerServerEvent('climate:setConfig', key, input[1])
        end
        Wait(200)
        openConfigMenu()
    end)

    lib.showMenu('climate_config_menu')
end
---#endregion menu

RegisterNetEvent('climate:openConfigMenu', openConfigMenu)
