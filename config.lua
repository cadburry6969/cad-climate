Debug = true

WeatherTypes = {
    'EXTRASUNNY',
    'CLEAR',
    'NEUTRAL',
    'SMOG',
    'FOGGY',
    'OVERCAST',
    'CLOUDS',
    'CLEARING',
    'RAIN',
    'THUNDER',
    'SNOW',
    'BLIZZARD',
    'SNOWLIGHT',
    'XMAS',
    'HALLOWEEN',
}

DynamicWeatherList = {
    'EXTRASUNNY',
    'EXTRASUNNY',
    'EXTRASUNNY',
    'EXTRASUNNY',
    'EXTRASUNNY',
    'EXTRASUNNY',
    'CLEAR',
    'SMOG',
    'CLOUDS',
    'CLOUDS',
    'CLOUDS',
}

WeatherZones = {
    -- { coords: vec3, radius: float, weather: string, time: array[hour, min], dynamic: boolean },
    { coords = vector3(-1736.17, -171.67, 58.51), radius = 150.0, weather = 'THUNDER',  time = { 22, 00 }, dynamic = false }, -- GRAVE YARD
    { coords = vector3(465.79, 5574.07, 781.17),  radius = 750.0, weather = 'BLIZZARD', dynamic = false },                    -- MOUNT CHILLIAD
}

ForceXMAS = false

DynamicTimeChanger = 5 * 1000 -- 5 secs is every min of the server

WindStrength = 0.7
WaterOverrideStrength = 0.5
