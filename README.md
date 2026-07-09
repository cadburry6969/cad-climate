# cad-climate

Lightweight weather & time synchronization for FiveM, with location based climate zones and a fully in-game config editor. Built on [ox_lib](https://github.com/overextended/ox_lib), no database required.

---

## Features

- **Synced weather & time** across every client via `GlobalState` no per client drift.
- **Dynamic weather cycle** that rolls from a weighted pool as the in game day progresses.
- **Climate zones** named areas that force their own weather (and optionally a fixed time) while a player is inside them.
- **In-game config menu** (ox_lib) change every core setting, add and edit weather zones live, no restart needed. Changes are written straight back into `config.lua`.
- **Framework bridges** for `qb-weathersync`, `cd_easytime`, and `vSync` so existing scripts keep working.
- **Fully typed** every module ships LuaLS annotations for a clean editor experience.

---

## Requirements

| Dependency | Notes |
|------------|-------|
| [ox_lib](https://github.com/overextended/ox_lib) | Required. Provides the menu, dialogs, points, and command framework. |

Compatible with QBCore, Qbox, or standalone setups. The framework bridges auto disable themselves when the target resource isn't present.

---

## Installation

1. Download / clone this resource into your server's resources folder (e.g. `resources/cad-climate`).
2. Ensure `ox_lib` starts **before** this resource.
3. Add it to your `server.cfg`:

   ```cfg
   ensure ox_lib
   ensure cad-climate
   ```

4. Adjust the defaults in [`config.lua`](config.lua) to taste (or do it later in-game via `/climate_config`).

---

## Configuration

All settings live in [`config.lua`](config.lua). The scalar values below can also be changed live from the in-game menu, which persists them back to this file.

| Key | Type | Description |
|-----|------|-------------|
| `Debug` | `boolean` | Draws radius blips for every climate zone. |
| `WeatherTypes` | `string[]` | Every weather type the sync layer accepts. |
| `DynamicWeatherList` | `string[]` | Weighted pool the dynamic cycle rolls from (repeat entries to bias). |
| `WeatherZones` | `table[]` | Zones seeded at start see below. |
| `ForceXMAS` | `boolean` | Locks the whole map to `XMAS` weather. |
| `DynamicTimeChanger` | `integer` | Real milliseconds per in-game minute. |
| `WindStrength` | `number` | Global wind strength `[0.0 – 1.0]`. |
| `WaterOverrideStrength` | `number` | Global water/wave strength `[0.0 – 1.0]`. |

### Weather zone shape

```lua
{ name = 'Grave Yard', coords = vector3(-1736.17, -171.67, 58.51), radius = 150.0, weather = 'THUNDER', time = { 22, 0 }, dynamic = false }
```

| Field | Type | Description |
|-------|------|-------------|
| `name` | `string` | Label shown in the edit menu. |
| `coords` | `vector3` | Centre of the zone. |
| `radius` | `number` | Trigger radius in metres. |
| `weather` | `string` | Weather forced while inside. |
| `time` | `number[]?` | Optional clock time `{ hour, minute }` frozen while inside. |
| `dynamic` | `boolean` | Reserved flag for zone-local dynamic weather. |

---

## Commands

All commands are restricted to the `group.admin` ace.

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/climate_config` | — | Opens the in-game config menu (settings + add/edit zones). |
| `/weather` | `[name]` | Sets the global weather (e.g. `/weather THUNDER`). |
| `/time` | `[hour] [min]` | Sets the global time (e.g. `/time 12 30`). |
| `/freeze_weather` | — | Toggles the dynamic weather cycle on/off. |
| `/freeze_time` | — | Toggles the time progression on/off. |
| `/blackout` | — | Toggles the artificial-lights blackout. |
| `/current_climate` | — | Prints the current synced weather and time. |

---

## In-game menu

Run `/climate_config` to open the menu:

- **Toggle / edit settings** booleans are checkboxes; numbers open an input dialog. Changes apply instantly and save to `config.lua`.
- **Add weather zone** creates a zone at your current position (name, radius, weather, optional forced time, dynamic flag).
- **Edit weather zones** pick any zone by name to change its radius, weather, forced time, or dynamic flag.
- **Reset config** restores the values that were in `config.lua` at server start.

Zone changes render live on every connected client.

---

## Exports

Client exports for other resources to force weather/time locally (e.g. for cutscenes or instances):

```lua
-- Force a weather type. Pass freeze = true to hold it until released.
exports['cad-climate']:forceWeather(value, freeze)

-- Force a clock time. Pass freeze = true to hold it until released.
exports['cad-climate']:forceTime(hour, minute, freeze)
```

| Export | Parameters | Description |
|--------|------------|-------------|
| `forceWeather` | `value: string`, `freeze: boolean` | Applies a weather type; `freeze` holds it against the global sync. |
| `forceTime` | `hour: number`, `minute: number`, `freeze: boolean` | Overrides the clock; `freeze` holds it against the global sync. |

Call with `freeze = false` to release the override and resume syncing.

---

## Framework bridges

Located under `bridge/`. Each bridge self-disables when its target resource isn't running.

| Bridge | Provides |
|--------|----------|
| **qb** (`qb-weathersync`) | Re-implements the `qb-weathersync` exports (`setWeather`, `setTime`, `setBlackout`, `setTimeFreeze`, `getWeatherState`, `getTime`, …) and the `qb-weathersync:server:setWeather` / `setTime` events, plus the client `EnableSync` / `DisableSync` events. Secured with `command.weather` / `command.time` aces. |
| **cd** (`cd_easytime`) | Exposes the `cd_easytime:GetWeather` export and honours `cd_easytime:PauseSync`. Disable with `setr weather_disablecd true`. |
| **vsync** (`vSync`) | Honours the `vSync:toggle` event. |

> Do not run the real `qb-weathersync` alongside this resource  both register the same exports and will conflict.

---

## Notes

- **No database** runtime overrides are written back into `config.lua`, so they survive restarts.
- A zone's forced weather/time only holds while a player is **inside** the zone; on exit, global sync resumes.
- If your server auto-restarts resources on file change (dev file-watching), editing config in-game may bounce the resource. Disable file-watching in production.

---