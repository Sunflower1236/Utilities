local Creator = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors%20Entity%20Spawner/Source.lua"))()

-- Create entity
local entity = Creator.createEntity({
    CustomName = "Minion", -- Custom name of your entity
    Model = "11377415792", -- Can be GitHub file or rbxassetid
    Speed = 200, -- Percentage, 100 = default Rush speed
    DelayTime = 2, -- Time before starting cycles (seconds)
    HeightOffset = 0,
    CanKill = false,
    BreakLights = true,
    FlickerLights = {
        true, -- Enabled
        1, -- Time (seconds)
    },
    Cycles = {
        Min = 1,
        Max = 4,
        WaitTime = 2,
    },
    CamShake = {
        true, -- Enabled
        {5, 15, 0.1, 1}, -- Shake values (don't change if you don't know)
        100, -- Shake start distance (from Entity to you)
    },
    Jumpscare = {
        Image1 = "", -- Image1 url
        Image2 = "", -- Image2 url
        Shake = true,
        Sound1 = {
            9119732308, -- SoundId
            { Volume = 1 }, -- Sound properties
        },
    },
    CustomDialog = {"Your custom", "death message", "goes", "here."}, -- Custom death message (can be as long as you want)
})

-- Run the created entity
Creator.runEntity(entity)
