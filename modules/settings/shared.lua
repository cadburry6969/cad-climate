---#region type definitions
---A GTA weather type accepted by the natives and the sync layer.
---@alias WeatherType
---| 'EXTRASUNNY'
---| 'CLEAR'
---| 'NEUTRAL'
---| 'SMOG'
---| 'FOGGY'
---| 'OVERCAST'
---| 'CLOUDS'
---| 'CLEARING'
---| 'RAIN'
---| 'THUNDER'
---| 'SNOW'
---| 'BLIZZARD'
---| 'SNOWLIGHT'
---| 'XMAS'
---| 'HALLOWEEN'

---A clock time expressed as `{ hour, minute }`.
---@alias ClimateTime number[]

---Config keys that can be overridden live from the in-game menu.
---@alias ClimateSettingKey
---| 'Debug'
---| 'ForceXMAS'
---| 'DynamicTimeChanger'
---| 'WindStrength'
---| 'WaterOverrideStrength'

---A single climate zone that forces weather/time while a player is inside it.
---@class ClimateZone
---@field name string Human-readable label shown in the edit menu.
---@field coords vector3|{ x: number, y: number, z: number } Centre of the zone.
---@field radius number Trigger radius, in metres.
---@field weather WeatherType Weather forced while inside the zone.
---@field time? ClimateTime Optional clock time frozen while inside the zone.
---@field dynamic boolean Reserved flag for zone-local dynamic weather.

---Full configuration table returned by `config.lua`.
---@class ClimateConfig
---@field Debug boolean Draws zone radius blips when true.
---@field WeatherTypes WeatherType[] Every weather type the sync layer accepts.
---@field DynamicWeatherList WeatherType[] Weighted pool the dynamic cycle rolls from.
---@field WeatherZones ClimateZone[] Zones seeded at resource start.
---@field ForceXMAS boolean Locks the whole map to the XMAS weather type.
---@field DynamicTimeChanger integer Real milliseconds per in-game minute.
---@field WindStrength number Global wind strength [0.0-1.0].
---@field WaterOverrideStrength number Global water/wave strength [0.0-1.0].

---The subset of `ClimateConfig` that is runtime-overridable.
---@class ClimateSettings
---@field Debug boolean
---@field ForceXMAS boolean
---@field DynamicTimeChanger integer
---@field WindStrength number
---@field WaterOverrideStrength number

---Replicated GlobalState fields owned by this resource.
---@class ClimateState
---@field WeatherSyncing WeatherType Weather every client renders.
---@field TimeSyncing integer Synced hour [0-24].
---@field TimeMinutesSyncing integer Synced minute [0-60].
---@field FreezeTimeSyncing boolean Global time freeze.
---@field FreezeWeatherSyncing boolean Global weather freeze.
---@field BlackoutSyncing boolean Artificial-lights blackout.
---@field ClimateSettings table<ClimateSettingKey, boolean|number> Live setting overrides.
---@field ClimateZones ClimateZone[] Active weather zones.
---#endregion type definitions

---Config table loaded once from `config.lua`; treated as the default values.
---@type ClimateConfig
Config = lib.load('config')

---Snapshot of the overridable defaults captured at resource start.
---@type ClimateSettings
local defaults = {
    Debug = Config.Debug,
    ForceXMAS = Config.ForceXMAS,
    DynamicTimeChanger = Config.DynamicTimeChanger,
    WindStrength = Config.WindStrength,
    WaterOverrideStrength = Config.WaterOverrideStrength,
}

---Returns the live override for a setting, falling back to the config default.
---@param key ClimateSettingKey
---@return boolean|number|nil value
function GetSetting(key)
    ---@type table<ClimateSettingKey, boolean|number>?
    local overrides = GlobalState.ClimateSettings
    if overrides and overrides[key] ~= nil then
        return overrides[key]
    end
    return defaults[key]
end

---Returns the default (server-start) values for every overridable setting.
---@return ClimateSettings defaults
function GetSettingDefaults()
    return defaults
end
