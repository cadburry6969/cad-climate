return {
    Debug = true,

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
    },

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
    },

    -- { name: string, coords: vec3, radius: float, weather: string, time: array[hour, min], dynamic: boolean },
    WeatherZones = {
        { name = 'Grave Yard', coords = vector3(-1736.17, -171.67, 58.51), radius = 150.0, weather = 'THUNDER', time = { 22, 0 }, dynamic = false },
        { name = 'Mount Chiliad', coords = vector3(465.79, 5574.07, 781.17), radius = 750.0, weather = 'BLIZZARD', dynamic = false },
    },

    ForceXMAS = false,

    DynamicTimeChanger = 5000,

    WindStrength = 0.7,
    WaterOverrideStrength = 0.5,
}
