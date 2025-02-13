-- Services

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local ReSt = game:GetService("ReplicatedStorage")
local CG = game:GetService("CoreGui")
local TS = game:GetService("TweenService")

-- Variables

local Plr = Players.LocalPlayer
local Char = Plr.Character or Plr.CharacterAdded:Wait()
local Root = Char:WaitForChild("HumanoidRootPart")
local Hum = Char:WaitForChild("Humanoid")

local FindPartOnRayWithIgnoreList = workspace.FindPartOnRayWithIgnoreList
local StaticRushSpeed = 50
local MinTeaseSize = 150
local MaxTeaseSize = 300

local SelfModules = {
    Functions = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Functions.lua"))(),
}
local ModuleScripts = {
    MainGame = require(Plr.PlayerGui.MainUI.Initiator.Main_Game),
    ModuleEvents = require(ReSt.ClientModules.Module_Events),
}
local DefaultConfig = {
    Speed = 100,
    DelayTime = 2,
    HeightOffset = 0,
    CanKill = true,
    BreakLights = true,
    FlickerLights = {
        true,
        1,
    },
    Cycles = {
        Min = 1,
        Max = 1,
        WaitTime = 2,
    },
    CamShake = {
        true,
        {5, 15, 0.1, 1},
        100,
    },
    CustomDialog = {},
}
local StoredSounds = {}

local Creator = {}

-- Misc Functions

local function drag(model, objB, speed)
    local reached = false

    local con; con = RS.Stepped:Connect(function(_, step)
        local posA = model.PrimaryPart.Position
        local posB = objB.Position
        local diff = Vector3.new(posB.X, 0, posB.Z) - Vector3.new(posA.X, 0, posA.Z)

        if diff.Magnitude > 0.1 then
            model:SetPrimaryPartCFrame(CFrame.new(posA + diff.Unit * math.min(step * speed, diff.Magnitude - 0.05)))
        else
            reached = true
        end
    end)

    repeat task.wait() until reached
    
    con:Disconnect()
end

local function playSound(soundId, properties)
    for i, v in next, StoredSounds do
        v:Destroy()
        StoredSounds[i] = nil
    end

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://".. ({string.gsub(soundId, "%D", "")})[1]
    sound.Playing = true
    sound.Parent = workspace

    for i, v in next, properties do
        if i ~= "SoundId" and i ~= "Playing" and i ~= "Parent" then
            sound[i] = v
        end
    end

    StoredSounds[#StoredSounds + 1] = sound

    return sound
end

-- Functions

Creator.createEntity = function(config)
    -- Prepare configs

    assert(typeof(config) == "table")
    assert(config.Model)

    for i, v in next, DefaultConfig do
        if config[i] == nil then
            config[i] = DefaultConfig[i]
        end
    end
    
    config.Speed = StaticRushSpeed / 100 * config.Speed

    -- Obtain custom model

    local entityModel = nil

    if tonumber(config.Model) or string.find(config.Model, "rbxassetid") then
        local assetId = string.gsub(config.Model, "%D", "")

        entityModel = game:GetObjects("rbxassetid://".. assetId)[1]
    else
        writefile("customEntity.txt", game:HttpGet(config.Model))

        entityModel = game:GetObjects((getcustomasset or getsynasset)("customEntity.txt"))[1]

        delfile("customEntity.txt")
    end

    if entityModel then
        local pPart = entityModel.PrimaryPart or entityModel:FindFirstChildOfClass("Part")

        if pPart then
            entityModel.PrimaryPart = pPart
            pPart.Anchored = true

            if config.CustomName then
                entityModel.Name = config.CustomName
            end

            for _, v in next, entityModel:GetDescendants() do
                if v:IsA("BasePart") then
                    v.CanCollide = false
                end
            end
            
            return { Model = entityModel, Config = config }
        else
            warn("Failure - Could not obtain model's PrimaryPart")
        end
    else
        warn("Failure - Could not obtain entity model")
    end
end

Creator.runEntity = function(entity)
    assert(typeof(entity) == "table")
    assert(entity.Model and entity.Model.PrimaryPart and entity.Config)

    -- Obtain nodes

    local nodes = {}

    for _, room in next, workspace.CurrentRooms:GetChildren() do
        if room:FindFirstChild("Nodes") then
            for _, node in next, room.Nodes:GetChildren() do
                nodes[#nodes + 1] = node
            end
        end
    end

    -- Death & Camera shaking

    local movementCon = nil

    movementCon = RS.Stepped:Connect(function()
        if entity.Config.CanKill and not Char:GetAttribute("Hiding") then
            local posA = entity.Model.PrimaryPart.Position
            local posB = Root.Position
            local found = FindPartOnRayWithIgnoreList(workspace, Ray.new(posA, (posB - posA).Unit * 100), { entity.Model })

            if found and found.IsDescendantOf(found, Char) then
                movementCon:Disconnect()

                if typeof(entity.Config.Jumpscare) == "table" then
                    Creator.runJumpscare(entity.Config.Jumpscare)
                end
                
                Hum.Health = 0

                if #entity.Config.CustomDialog > 0 then
                    ReSt.GameStats["Player_".. Plr.Name].Total.DeathCause.Value = entity.Model.Name
                    debug.setupvalue(getconnections(ReSt.Bricks.DeathHint.OnClientEvent)[1].Function, 1, entity.Config.CustomDialog)
                end
            end
        end
        
        local camShake = entity.Config.CamShake
        local mag = (Root.Position - entity.Model.PrimaryPart.Position).Magnitude

        if camShake[1] and mag <= camShake[3] then
            local shakeRep = {}

            for i, v in next, camShake[2] do
                shakeRep[i] = v
            end
            shakeRep[1] = camShake[2][1] / camShake[3] * (camShake[3] - mag)
            
            ModuleScripts.MainGame.camShaker.ShakeOnce(ModuleScripts.MainGame.camShaker, table.unpack(shakeRep))
            shakeRep = nil
        end
    end)

    -- Pre-cycle setup

    local firstRoom = workspace.CurrentRooms:GetChildren()[1]

    entity.Model:SetPrimaryPartCFrame( (firstRoom:FindFirstChild("RoomStart") and firstRoom.RoomStart.CFrame or nodes[1].CFrame + Vector3.new(0, 3.5, 0)) + Vector3.new(0, entity.Config.HeightOffset, 0) )
    entity.Model.Parent = workspace

    if entity.Config.FlickerLights[1] then
        task.spawn(ModuleScripts.ModuleEvents.flickerLights, workspace.CurrentRooms[Plr:GetAttribute("CurrentRoom")], entity.Config.FlickerLights[2])
    end

    task.wait(entity.Config.DelayTime or 0)

    -- Go through cycles

    local cycles = entity.Config.Cycles

    for _ = 1, math.random(cycles.Min, cycles.Max) do
        for i = 1, #nodes, 1 do
            if entity.Config.BreakLights then
                ModuleScripts.ModuleEvents.breakLights(nodes[i].Parent.Parent)
            end

            drag(entity.Model, nodes[i], entity.Config.Speed)
        end

        if cycles.Max > 1 then
            for i = #nodes, 1, -1 do
                drag(entity.Model, nodes[i], entity.Config.Speed)
            end
        end

        task.wait(cycles.WaitTime or 0)
    end

    -- Remove entity after cycles

    if movementCon then
        movementCon:Disconnect()
    end

    entity.Model:Destroy()
end

Creator.runJumpscare = function(config)
    -- Pre-setup

    local image1 = LoadCustomAsset(config.Image1)
    local image2 = LoadCustomAsset(config.Image2)
    local sound1, sound2 = nil, nil

    Char:SetPrimaryPartCFrame(CFrame.new(0, 9e9, 0))

    -- UI Construction

    local JumpscareGui = Instance.new("ScreenGui")
    local Background = Instance.new("Frame")
    local Face = Instance.new("ImageLabel")

    JumpscareGui.Name = "JumpscareGui"
    JumpscareGui.IgnoreGuiInset = true
    JumpscareGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    Background.Name = "Background"
    Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Background.BorderSizePixel = 0
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.ZIndex = 999

    Face.Name = "Face"
    Face.AnchorPoint = Vector2.new(0.5, 0.5)
    Face.BackgroundTransparency = 1
    Face.Position = UDim2.new(0.5, 0, 0.5, 0)
    Face.Size = UDim2.new(0, 150, 0, 150)
    Face.Image = image1

    Face.Parent = Background
    Background.Parent = JumpscareGui
    JumpscareGui.Parent = CG

    -- Tease

    if config.Tease[1] then
        if typeof(config.Sound1) == "table" then
            sound1 = playSound(config.Sound1[1], config.Sound1[2])
        end

        local rdmTease = math.random(config.Tease[2].Min, config.Tease[2].Max)

        for _ = config.Tease[2].Min, rdmTease do
            task.wait(math.random(100, 200) / 100)

            local growFactor = (MaxTeaseSize - MinTeaseSize) / rdmTease
            Face.Size = UDim2.new(0, Face.AbsoluteSize.X + growFactor, 0, Face.AbsoluteSize.Y + growFactor)
        end
        
        task.wait(math.random(100, 200) / 100)
    end

    -- Scare

    if config.Flashing[1] then
        task.spawn(function()
            while JumpscareGui.Parent do
                Background.BackgroundColor3 = config.Flashing[2]
                task.wait(math.random(25, 100) / 1000)
                Background.BackgroundColor3 = Color3.new(0, 0, 0)
                task.wait(math.random(25, 100) / 1000)
            end
        end)
    end

    if config.Shake then
        task.spawn(function()
            local origin = Face.Position

            while JumpscareGui.Parent do
                Face.Position = origin + UDim2.new(0, math.random(-10, 10), 0, math.random(-10, 10))
                Face.Rotation = math.random(-5, 5)

                task.wait()
            end
        end)
    end

    if typeof(config.Sound2) == "table" then
        sound2 = playSound(config.Sound2[1], config.Sound2[2])
    end

    Face.Image = image2
    Face.Size = UDim2.new(0, 750, 0, 750)
    TS:Create(Face, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { Size = UDim2.new(0, 1500, 0, 1500), ImageTransparency = 0.5 }):Play()
    task.wait(1)
    JumpscareGui:Destroy()

    if sound1 then
        sound1:Stop()
    end

    if sound2 then
        sound2:Stop()
    end
end

-- Scripts

return Creator
