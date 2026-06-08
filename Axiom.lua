-- ==============================================================================
-- AXIOM HUB UI FRAMEWORK - FINAL MASTER BUILD (Draggable Icon Patch)
-- Features: True Teleport Eggs, Upcycle Replacements, Rarity Sorting
-- Credits: Dev by zXIJz | UI by zXIJz
-- ==============================================================================

-- GLOBAL KILL SWITCH: Destroys ghost loops if you re-execute the script
if _G.AxiomHub_KillSwitch then
    _G.AxiomHub_KillSwitch()
end

local isUnloaded = false 
_G.AxiomHub_KillSwitch = function()
    isUnloaded = true
end

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local UI_PARENT = RunService:IsStudio() and LocalPlayer:WaitForChild("PlayerGui") or CoreGui

-- ==============================================================================
-- THEMES & CORE UI HELPERS
-- ==============================================================================
local Theme = {
    MainBg      = Color3.fromRGB(12, 12, 12),
    SidebarBg   = Color3.fromRGB(18, 18, 18),
    SectionBg   = Color3.fromRGB(24, 24, 26),
    ElementBg   = Color3.fromRGB(35, 35, 40),
    ElementHov  = Color3.fromRGB(45, 45, 50),
    Accent      = Color3.fromRGB(255, 50, 50),
    Text        = Color3.fromRGB(255, 255, 255),
    TextDim     = Color3.fromRGB(160, 160, 170),
    Border      = Color3.fromRGB(45, 45, 50),
    Font        = Enum.Font.GothamMedium,
    FontBold    = Enum.Font.GothamBold,
}

local function Create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do inst[k] = v end
    return inst
end

local function Tween(instance, properties, duration, style)
    local tInfo = TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tInfo, properties)
    tween:Play()
    return tween
end

-- ==============================================================================
-- CONFIGURATION SYSTEM
-- ==============================================================================
local ConfigFileName = "AxiomHub_SavedConfig.json"

local Library = {
    ActiveTab = nil,
    Windows = {},
    Flags = {
        ["Screen Notifications"] = true,
        ["CustomBackground"] = "",
        ["PlantOverrides"] = {},
        ["Anti-AFK"] = true
    }, 
    Settings = { ToggleKey = Enum.KeyCode.RightShift, Watermark = true },
    SessionStart = os.time(),
    BgImage = nil,
    PurchasedSeeds = {},
    ReplacedCrops = {},
    UpcycleUpgrades = {}
}

local function LoadConfig()
    if type(readfile) == "function" and type(isfile) == "function" then
        pcall(function()
            if isfile(ConfigFileName) then
                local savedData = HttpService:JSONDecode(readfile(ConfigFileName))
                if type(savedData) == "table" then
                    for k, v in pairs(savedData) do
                        Library.Flags[k] = v
                    end
                    if not Library.Flags["PlantOverrides"] then
                        Library.Flags["PlantOverrides"] = {}
                    end
                end
            end
        end)
    end
end

local function SaveConfig()
    if type(writefile) == "function" then
        pcall(function()
            writefile(ConfigFileName, HttpService:JSONEncode(Library.Flags))
        end)
    end
end

LoadConfig()

function Library:SetBackground(id)
    Library.Flags["CustomBackground"] = id
    SaveConfig()
    if not Library.BgImage then return end
    
    if id == nil or id == "" then
        Library.BgImage.Image = ""
        Library.BgImage.ImageTransparency = 1
    else
        local numId = string.match(id, "%d+")
        if numId then
            Library.BgImage.Image = "rbxthumb://type=Asset&id=" .. numId .. "&w=768&h=432"
            Library.BgImage.ImageTransparency = 0.25 
        else
            Library.BgImage.Image = ""
            Library.BgImage.ImageTransparency = 1
        end
    end
end

-- ==============================================================================
-- MASTER DATABASES & RANKINGS
-- ==============================================================================
local RarityColors = {
    ["Common"] = ColorSequence.new(Color3.fromRGB(200, 200, 200)),
    ["Uncommon"] = ColorSequence.new(Color3.fromRGB(100, 255, 100)),
    ["Rare"] = ColorSequence.new(Color3.fromRGB(100, 150, 255)),
    ["Epic"] = ColorSequence.new(Color3.fromRGB(200, 100, 255)),
    ["Legendary"] = ColorSequence.new(Color3.fromRGB(255, 150, 50)),
    ["Secret"] = ColorSequence.new(Color3.fromRGB(255, 255, 100)),
    ["Prismatic"] = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 200)), ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255))}),
    ["Divine"] = ColorSequence.new(Color3.fromRGB(100, 255, 255)),
    ["Exotic"] = ColorSequence.new(Color3.fromRGB(255, 50, 50)),
    ["Transcendent"] = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
    })
}

local RarityList = {
    {Name = "Common", Rarity = "Common"}, {Name = "Uncommon", Rarity = "Uncommon"},
    {Name = "Rare", Rarity = "Rare"}, {Name = "Epic", Rarity = "Epic"},
    {Name = "Legendary", Rarity = "Legendary"}, {Name = "Secret", Rarity = "Secret"},
    {Name = "Prismatic", Rarity = "Prismatic"}, {Name = "Divine", Rarity = "Divine"},
    {Name = "Exotic", Rarity = "Exotic"}, {Name = "Transcendent", Rarity = "Transcendent"}
}

local SeedData = {
    {Name = "Carrot", Rarity = "Common", Rank = 1}, {Name = "Beetroot", Rarity = "Common", Rank = 2}, {Name = "Pumpkin", Rarity = "Common", Rank = 3},
    {Name = "Wheat", Rarity = "Uncommon", Rank = 4}, {Name = "Melon", Rarity = "Uncommon", Rank = 5}, {Name = "Onion", Rarity = "Uncommon", Rank = 6}, {Name = "Cantaloupe", Rarity = "Uncommon", Rank = 7}, {Name = "Watermelon", Rarity = "Uncommon", Rank = 8},
    {Name = "Blueberry", Rarity = "Rare", Rank = 9}, {Name = "Cabbage", Rarity = "Rare", Rank = 10}, {Name = "Grape", Rarity = "Rare", Rank = 11}, {Name = "Bamboo", Rarity = "Rare", Rank = 12}, {Name = "Peach", Rarity = "Rare", Rank = 13},
    {Name = "Corn", Rarity = "Epic", Rank = 14}, {Name = "Plum", Rarity = "Epic", Rank = 15}, {Name = "Cauliflower", Rarity = "Epic", Rank = 16}, {Name = "Twinflame Tulip", Rarity = "Epic", Rank = 17}, {Name = "Nectarine", Rarity = "Epic", Rank = 18}, {Name = "Honeysuckle", Rarity = "Epic", Rank = 19}, {Name = "Sunflower", Rarity = "Epic", Rank = 20}, {Name = "Martian Melon", Rarity = "Epic", Rank = 21}, {Name = "Citrus", Rarity = "Epic", Rank = 22},
    {Name = "Spring Onion", Rarity = "Legendary", Rank = 23}, {Name = "Mango", Rarity = "Legendary", Rank = 24}, {Name = "Mushroom", Rarity = "Legendary", Rank = 25}, {Name = "Amulet Anemone", Rarity = "Legendary", Rank = 26}, {Name = "Potato", Rarity = "Legendary", Rank = 27}, {Name = "Banana", Rarity = "Legendary", Rank = 28},
    {Name = "Strawberry", Rarity = "Secret", Rank = 29}, {Name = "Monsoon Crown", Rarity = "Secret", Rank = 30}, {Name = "Admin Crownflower", Rarity = "Secret", Rank = 31}, {Name = "Glowshroom", Rarity = "Secret", Rank = 32}, {Name = "Beanstalk", Rarity = "Secret", Rank = 33}, {Name = "Glasswing", Rarity = "Secret", Rank = 34}, {Name = "Tomato", Rarity = "Secret", Rank = 35}, {Name = "Starfruit", Rarity = "Secret", Rank = 36},
    {Name = "Apple", Rarity = "Prismatic", Rank = 37}, {Name = "Duoheart Daisy", Rarity = "Prismatic", Rank = 38}, {Name = "Cherry Blossom", Rarity = "Prismatic", Rank = 39}, {Name = "Galaxy Hibiscus", Rarity = "Prismatic", Rank = 40}, {Name = "Blood Orange", Rarity = "Prismatic", Rank = 41}, {Name = "Pineapple", Rarity = "Prismatic", Rank = 42}, {Name = "Iron Fern", Rarity = "Prismatic", Rank = 43}, {Name = "Cinnamon", Rarity = "Prismatic", Rank = 44}, {Name = "Garlic", Rarity = "Prismatic", Rank = 45}, {Name = "Hex Sprout", Rarity = "Prismatic", Rank = 46}, {Name = "Rush Root", Rarity = "Prismatic", Rank = 47},
    {Name = "Diamond Blossom", Rarity = "Divine", Rank = 48}, {Name = "Golden Apple", Rarity = "Divine", Rank = 49}, {Name = "Pomegranate", Rarity = "Divine", Rank = 50}, {Name = "Horned Melon", Rarity = "Divine", Rank = 51}, {Name = "Admin Bloom", Rarity = "Divine", Rank = 52}, {Name = "Cocoa", Rarity = "Divine", Rank = 53}, {Name = "Crystalberry", Rarity = "Divine", Rank = 54}, {Name = "Dreadcap", Rarity = "Divine", Rank = 55}, {Name = "Compost Hydra", Rarity = "Divine", Rank = 56},
    {Name = "Kiwi", Rarity = "Exotic", Rank = 57}, {Name = "Moonflower", Rarity = "Exotic", Rank = 58}, {Name = "Passion Fruit", Rarity = "Exotic", Rank = 59}, {Name = "Striped Starfruit", Rarity = "Exotic", Rank = 60}, {Name = "Pepper", Rarity = "Exotic", Rank = 61}, {Name = "Heartvine", Rarity = "Exotic", Rank = 62}, {Name = "Truckers Delight", Rarity = "Exotic", Rank = 63}, {Name = "Void Fruit", Rarity = "Exotic", Rank = 64}, {Name = "Elder Dragonroot", Rarity = "Exotic", Rank = 65}, {Name = "Crimson Higanbana", Rarity = "Exotic", Rank = 66}, {Name = "Dragonfruit", Rarity = "Exotic", Rank = 67},
    {Name = "Dragon Scale Aloe", Rarity = "Exotic", Rank = 67.5}, {Name = "Silver Artichoke", Rarity = "Divine", Rank = 53.5},
    {Name = "Papaya", Rarity = "Transcendent", Rank = 69}, {Name = "Durian", Rarity = "Transcendent", Rank = 70}, {Name = "Ghost Pepper", Rarity = "Transcendent", Rank = 71}, {Name = "Ember Fruit", Rarity = "Transcendent", Rank = 72}, {Name = "Queens Blossom", Rarity = "Transcendent", Rank = 73}, {Name = "Heart of Corruption", Rarity = "Transcendent", Rank = 74}, {Name = "Soulbound Orchid", Rarity = "Transcendent", Rank = 75}, {Name = "Aurora Lotus", Rarity = "Transcendent", Rank = 76}, {Name = "Garden Golem", Rarity = "Transcendent", Rank = 77}
}

local GearData = {
    {Name = "Normal Fertilizer", Price = 500000}, {Name = "Acid Spray", Price = 1000000},
    {Name = "Normal Pet Treat", Price = 1000000}, {Name = "Wet Spray", Price = 10000000},
    {Name = "Strong Fertilizer", Price = 50000000}, {Name = "Strong Pet Treat", Price = 75000000},
    {Name = "Frozen Spray", Price = 750000000}, {Name = "Autum Spray", Price = 1000000000},
    {Name = "Void Spray", Price = 10000000000}, {Name = "Super Fertilizer", Price = 15000000000},
    {Name = "Super Pet Treat", Price = 20000000000}, {Name = "Radioactive Spray", Price = 100000000000},
    {Name = "Rainbow Spray", Price = 1000000000000}, {Name = "Prismatic Fertilizer", Price = 25000000000000},
    {Name = "Cosmic Spray", Price = 25000000000000}, {Name = "Bubblegum Spray", Price = 250000000000000},
    {Name = "Fire Spray", Price = 1000000000000000}
}

local SprayRanks = {
    ["Wet Spray"] = 1, ["Frozen Spray"] = 2, ["Autumn Spray"] = 3,
    ["Void Spray"] = 4, ["Radioactive Spray"] = 5, ["Rainbow Spray"] = 6,
    ["Cosmic Spray"] = 7, ["Bubblegum Spray"] = 8, ["Fire Spray"] = 9
}

local FertRanks = {
    ["Normal Fertilizer"] = 1, ["Strong Fertilizer"] = 2,
    ["Super Fertilizer"] = 3, ["Prismatic Fertilizer"] = 4
}

local FertOnlyData = {}
local SprayOnlyData = {}
for _, g in ipairs(GearData) do
    if string.find(g.Name, "Spray") then table.insert(SprayOnlyData, g)
    else table.insert(FertOnlyData, g) end
end

-- ==============================================================================
-- SHARED UTILS
-- ==============================================================================
local SharedUtils = nil
pcall(function()
    SharedUtils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SharedUtils"))
end)

-- ==============================================================================
-- LOGIC HELPER FUNCTIONS
-- ==============================================================================
local function safeIpairs(t)
    if type(t) == "table" then return ipairs(t) end
    return ipairs({})
end

local function parsePriceString(str)
    str = str:upper():gsub("[$,]", "")
    if str:find("MAX") then return math.huge end
    if str:sub(-2) == "QD" then
        local num = tonumber(str:sub(1, -3))
        if num then return num * 1e15 end
    end
    local suffixes = {K = 1e3, M = 1e6, B = 1e9, T = 1e12}
    local lastChar = str:sub(-1)
    if suffixes[lastChar] then
        local num = tonumber(str:sub(1, -2))
        if num then return num * suffixes[lastChar] end
    end
    return tonumber(str) or 0
end

local function getPlayerCash()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local cashObj = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money") or leaderstats:FindFirstChildWhichIsA("ValueBase")
        if cashObj then
            local val = cashObj.Value
            if type(val) == "string" then return parsePriceString(val)
            elseif type(val) == "number" then return val end
        end
    end
    return 0
end

local function safeFirePrompt(prompt)
    if not prompt then return end
    if fireproximityprompt then
        pcall(fireproximityprompt, prompt)
    else
        pcall(function()
            prompt:InputBegan(Enum.UserInputType.Keyboard)
            local holdDuration = prompt.HoldDuration or 0
            task.wait(holdDuration + 0.1)
            prompt:InputEnded(Enum.UserInputType.Keyboard)
        end)
    end
end

local function findPlotsFolder()
    if workspace:FindFirstChild("Plots") then return workspace.Plots end
    if workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Plots") then return workspace.Map.Plots end
    return nil
end

local function getPlayerPlot()
    local plotsFolder = findPlotsFolder()
    if not plotsFolder then return nil end
    
    for _, plot in safeIpairs(plotsFolder:GetChildren()) do
        local ownerValue = plot:FindFirstChild("Owner") or plot:FindFirstChild("TycoonOwner") or plot:FindFirstChildWhichIsA("StringValue")
        if ownerValue and (ownerValue.Value == LocalPlayer.Name or ownerValue.Value == LocalPlayer.DisplayName) then 
            return plot 
        end
        if plot:GetAttribute("Owner") == LocalPlayer.Name or plot:GetAttribute("PlotOwner") == LocalPlayer.Name then 
            return plot 
        end
    end
    
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local closestPlot, minDist = nil, math.huge
        for _, plot in safeIpairs(plotsFolder:GetChildren()) do
            if plot:IsA("Model") then
                local dist = (plot:GetPivot().Position - char.HumanoidRootPart.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closestPlot = plot
                end
            end
        end
        if minDist < 250 then return closestPlot end
    end
    return nil
end

local function GetPlantRank(pName)
    for _, s in ipairs(SeedData) do
        if s.Name == pName then return s.Rank end
    end
    return 1
end

local function GetPlantIncome(pName, pMut, pLevel)
    local income = 0
    if SharedUtils and type(SharedUtils.CalculateIncome) == "function" then
        pcall(function() income = SharedUtils.CalculateIncome(pName, pMut, pLevel, 0) end)
    end
    
    if income == 0 then
        local rank = GetPlantRank(pName)
        local mutBonus = 1
        if pMut == "Fire" then mutBonus = 10
        elseif pMut == "Bubblegum" then mutBonus = 9
        elseif pMut == "Cosmic" then mutBonus = 8
        elseif pMut == "Rainbow" then mutBonus = 6.5
        elseif pMut == "Admin" then mutBonus = 5
        elseif pMut == "Radioactive" then mutBonus = 3.25
        elseif pMut == "Void" then mutBonus = 2.25
        elseif pMut ~= "Normal" and pMut ~= "None" then mutBonus = 2 end
        income = (rank * 100 * mutBonus) + pLevel
    end
    
    return income
end

local function EquipItemByName(nameMatch)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if not hum then return end
    
    local items = LocalPlayer.Backpack:GetChildren()
    for _, item in ipairs(char:GetChildren()) do table.insert(items, item) end
    
    for _, item in ipairs(items) do
        if item:IsA("Tool") then
            local cleanName = item.Name:gsub("%s*%(x%d+%)", "")
            if string.find(cleanName, nameMatch, 1, true) or string.find(item.Name, nameMatch, 1, true) then
                if item.Parent ~= char then
                    hum:EquipTool(item)
                end
                return item
            end
        end
    end
    return nil
end

local function MakeDraggable(dragArea, target)
    local dragging, dragInput, dragStart, startPos
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function FormatNumber(num)
    if num >= 1e12 then return string.format("%.2fT", num/1e12)
    elseif num >= 1e9 then return string.format("%.2fB", num/1e9)
    elseif num >= 1e6 then return string.format("%.2fM", num/1e6)
    elseif num >= 1e3 then return string.format("%.2fK", num/1e3)
    else return tostring(math.floor(num)) end
end

-- ==============================================================================
-- CAMERA BLOCKER & TELEPORT VARIABLES
-- ==============================================================================
local isBuyingEgg = false
local lockedCamCFrame = nil

RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if not cam then return end
    
    if isBuyingEgg and lockedCamCFrame then
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = lockedCamCFrame
    elseif Library.Flags["Auto Buy Egg (Common)"] or Library.Flags["Auto Buy Egg (Rare)"] or Library.Flags["Auto Buy Egg (Epic)"] then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum and cam.CameraSubject ~= hum then
            cam.CameraSubject = hum
            cam.CameraType = Enum.CameraType.Custom
        end
    end
end)

-- Anti-AFK Hook
LocalPlayer.Idled:Connect(function()
    if Library.Flags["Anti-AFK"] then
        VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    end
end)

-- ==============================================================================
-- NOTIFICATION ENGINE
-- ==============================================================================
if UI_PARENT:FindFirstChild("AxiomHub_Core") then
    UI_PARENT.AxiomHub_Core:Destroy()
end

local ScreenGui = Create("ScreenGui", { Name = "AxiomHub_Core", Parent = UI_PARENT, ResetOnSpawn = false, IgnoreGuiInset = true })
local NotifContainer = Create("Frame", { Name = "NotifContainer", Parent = ScreenGui, Size = UDim2.new(0, 300, 1, -40), Position = UDim2.new(1, -320, 0, 20), BackgroundTransparency = 1, ZIndex = 1000 })
local NotifList = Create("UIListLayout", { Parent = NotifContainer, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8) })

local ActiveNotifications = {}

local function createNotification(title, msg)
    if not Library.Flags["Screen Notifications"] then return end
    
    local notifKey = title .. "|" .. msg
    local existing = ActiveNotifications[notifKey]
    
    if existing and not existing.Fading then
        existing.Count = existing.Count + 1
        existing.MsgLabel.Text = msg .. " (x" .. existing.Count .. ")"
        existing.Expiry = os.clock() + 3.5
        return
    end
    
    local Toast = Create("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = Color3.fromRGB(24, 24, 26), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 1001 })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Toast })
    local Stroke = Create("UIStroke", { Color = Color3.fromRGB(255, 50, 50), Thickness = 1, Parent = Toast, Transparency = 1 })
    
    local AccentBar = Create("Frame", { Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 50, 50), Parent = Toast, BackgroundTransparency = 1, ZIndex = 1002 })
    Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = AccentBar })
    
    local tLabel = Create("TextLabel", { Parent = Toast, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 12, 0, 8), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 1002 })
    local mLabel = Create("TextLabel", { Parent = Toast, Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 12, 0, 26), BackgroundTransparency = 1, Text = msg, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(160, 160, 170), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTransparency = 1, ZIndex = 1002 })
    
    Toast.Parent = NotifContainer
    
    Tween(Toast, {BackgroundTransparency = 0}, 0.2)
    Tween(Stroke, {Transparency = 0}, 0.2)
    Tween(AccentBar, {BackgroundTransparency = 0}, 0.2)
    Tween(tLabel, {TextTransparency = 0}, 0.2)
    Tween(mLabel, {TextTransparency = 0}, 0.2)
    
    ActiveNotifications[notifKey] = {
        Frame = Toast,
        Stroke = Stroke,
        Accent = AccentBar,
        TitleLabel = tLabel,
        MsgLabel = mLabel,
        Count = 1,
        Expiry = os.clock() + 3.5,
        Fading = false
    }
end

task.spawn(function()
    while not isUnloaded do
        local currentTime = os.clock()
        for key, notif in pairs(ActiveNotifications) do
            if currentTime >= notif.Expiry and not notif.Fading then
                notif.Fading = true
                Tween(notif.Frame, {BackgroundTransparency = 1}, 0.2)
                Tween(notif.Stroke, {Transparency = 1}, 0.2)
                Tween(notif.Accent, {BackgroundTransparency = 1}, 0.2)
                Tween(notif.TitleLabel, {TextTransparency = 1}, 0.2)
                local fadeOut = Tween(notif.MsgLabel, {TextTransparency = 1}, 0.2)
                
                fadeOut.Completed:Connect(function()
                    if notif.Frame then notif.Frame:Destroy() end
                    ActiveNotifications[key] = nil
                end)
            end
        end
        task.wait(0.1)
    end
end)

-- ==============================================================================
-- GAME REMOTES & VARIABLES
-- ==============================================================================
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlotTransactionEvent = Remotes:WaitForChild("PlotUpgradeTransaction")
local SeedLuckEvent = Remotes:WaitForChild("UpgradeSeedLuck")
local SeedRollsEvent = Remotes:WaitForChild("UpgradeSeedRolls")
local UnlockPlotEvent = Remotes:WaitForChild("UnlockPlot")
local UpgradeFarmEvent = Remotes:WaitForChild("UpgradeFarm")
local BuySeedEvent = Remotes:WaitForChild("BuySeed")
local SellCratesEvent = Remotes:WaitForChild("SellCrates")
local RollSeedsEvent = Remotes:WaitForChild("RollSeeds")
local PlantSeedEvent = Remotes:WaitForChild("PlantSeed")
local UpgradePlantEvent = Remotes:WaitForChild("UpgradePlant")
local DiscardSeedEvent = Remotes:FindFirstChild("DiscardSeed")
local RemovePlantEvent = Remotes:FindFirstChild("RemovePlant")

local GearTransactionEvent = Remotes:WaitForChild("Gear"):WaitForChild("Transaction")

local AlertEvent = Remotes:WaitForChild("Alert")

local PlantRushFolder = Remotes:WaitForChild("PlantRush")
local PlantRushShootEvent = PlantRushFolder:WaitForChild("Shoot")
local DropClaimEvent = PlantRushFolder:WaitForChild("DropClaim")

local cachedPlot = nil

local function UpdatePurchasedSeedsUI()
    pcall(function()
        local pSeeds = {}
        for sName, count in pairs(Library.PurchasedSeeds) do
            table.insert(pSeeds, {name = sName, count = count})
        end
        table.sort(pSeeds, function(a, b) return a.count > b.count end)
        
        local pUI = {}
        for i=1, math.min(15, #pSeeds) do
            table.insert(pUI, {Type = "Label", Name = tostring(pSeeds[i].count) .. "x " .. pSeeds[i].name})
        end
        if #pUI == 0 then table.insert(pUI, {Type = "Label", Name = "No seeds purchased yet."}) end
        
        if _G.PurchasedSeedsListApi then
            _G.PurchasedSeedsListApi:Update(pUI)
        end
    end)
end

-- ==============================================================================
-- ANTI-ALERT HOOK
-- ==============================================================================
pcall(function()
    if getconnections then
        local conns = getconnections(AlertEvent.OnClientEvent)
        if type(conns) == "table" then
            for _, connection in ipairs(conns) do
                local originalFunction = connection.Function
                connection:Disable()
                AlertEvent.OnClientEvent:Connect(function(preset, alertType, message, ...)
                    if message == "Out of stock" or message == "Not enough cash!" then
                        return 
                    end
                    if originalFunction then
                        originalFunction(preset, alertType, message, ...)
                    end
                end)
            end
        end
    end
end)

-- ==============================================================================
-- MAIN WINDOW GENERATION
-- ==============================================================================
function Library:CreateWindow(config)
    local TitleText = config.Title or "AXIOM"
    local SubText = config.Subtitle or "HUB V1.0"

    local MainFrame = Create("Frame", { Name = "MainFrame", Parent = ScreenGui, Size = UDim2.new(0.85, 0, 0.85, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.MainBg, BorderSizePixel = 0, ClipsDescendants = true })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = MainFrame })
    Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = MainFrame })
    
    local BgImage = Create("ImageLabel", {
        Name = "BackgroundImage",
        Parent = MainFrame,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Image = "",
        ImageTransparency = 0.4, 
        ScaleType = Enum.ScaleType.Crop, 
        ZIndex = 1 
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = BgImage })
    Library.BgImage = BgImage

    local SizeConstraint = Create("UISizeConstraint", { Parent = MainFrame, MinSize = Vector2.new(400, 250), MaxSize = Vector2.new(1200, 800) })

    local DragHeader = Create("Frame", { Parent = MainFrame, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, ZIndex = 100 })
    MakeDraggable(DragHeader, MainFrame)

    local Sidebar = Create("Frame", { Parent = MainFrame, Size = UDim2.new(0, 180, 1, 0), BackgroundColor3 = Theme.SidebarBg, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 2 })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Sidebar }) 
    Create("Frame", { Parent = Sidebar, Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BackgroundColor3 = Theme.SidebarBg, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 2 })
    Create("Frame", { Parent = Sidebar, Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, ZIndex = 2 })

    local LogoText = Create("TextLabel", { Parent = Sidebar, Size = UDim2.new(1, -40, 0, 30), Position = UDim2.new(0, 15, 0, 25), BackgroundTransparency = 1, Text = TitleText, Font = Theme.FontBold, TextColor3 = Theme.Accent, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
    local SubLogoText = Create("TextLabel", { Parent = Sidebar, Size = UDim2.new(1, -40, 0, 15), Position = UDim2.new(0, 15, 0, 55), BackgroundTransparency = 1, Text = SubText, Font = Theme.Font, TextColor3 = Theme.TextDim, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })

    local TabContainer = Create("ScrollingFrame", { Parent = Sidebar, Size = UDim2.new(1, 0, 1, -110), Position = UDim2.new(0, 0, 0, 110), BackgroundTransparency = 1, ScrollBarThickness = 0, ZIndex = 2 })
    Create("UIListLayout", { Parent = TabContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })

    local ContentArea = Create("Frame", { Parent = MainFrame, Size = UDim2.new(1, -180, 1, 0), Position = UDim2.new(0, 180, 0, 0), BackgroundTransparency = 1, ZIndex = 2 })

    local ResizeHandle = Create("TextLabel", { Parent = MainFrame, Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -20, 1, -20), BackgroundTransparency = 1, Text = "◢", TextColor3 = Theme.TextDim, TextSize = 14, ZIndex = 100 })
    local resizing = false; local resizeStartMouse; local resizeStartSize
    
    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true; resizeStartMouse = input.Position; resizeStartSize = MainFrame.AbsoluteSize
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStartMouse
            local newWidth = math.clamp(resizeStartSize.X + delta.X, 400, 1200) 
            local newHeight = math.clamp(resizeStartSize.Y + delta.Y, 250, 800)
            MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = false end
    end)

    local FloatingToggle = Create("ImageButton", { 
        Parent = ScreenGui, 
        Size = UDim2.new(0, 50, 0, 50), 
        Position = UDim2.new(0.5, -25, 0, 20), 
        BackgroundColor3 = Theme.MainBg, 
        Image = "rbxassetid://77120991996054",
        Visible = false, 
        ZIndex = 100 
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = FloatingToggle })
    Create("UIStroke", { Color = Theme.Accent, Thickness = 2, Parent = FloatingToggle })
    
    MakeDraggable(FloatingToggle, FloatingToggle)

    local MinimizeBtn = Create("TextButton", { Parent = DragHeader, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(1, -45, 0, 5), BackgroundTransparency = 1, Text = "—", Font = Theme.FontBold, TextColor3 = Theme.TextDim, TextSize = 18, ZIndex = 101 })

    MinimizeBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        FloatingToggle.Visible = true
    end)

    local floatDragStart
    FloatingToggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            floatDragStart = input.Position
        end
    end)
    FloatingToggle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if floatDragStart and (input.Position - floatDragStart).Magnitude < 5 then
                MainFrame.Visible = true
                FloatingToggle.Visible = false
            end
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Library.Settings.ToggleKey then 
            MainFrame.Visible = not MainFrame.Visible 
        end
    end)

    local WindowAPI = {}
    local FirstTab = true

    function WindowAPI:CreateTab(TabName)
        local TabBtn = Create("TextButton", { Parent = TabContainer, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2 })
        local TabIndicator = Create("Frame", { Parent = TabBtn, Size = UDim2.new(0, 4, 0, 20), Position = UDim2.new(0, 0, 0.5, -10), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, ZIndex = 2 })
        Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = TabIndicator })
        local TabLabel = Create("TextLabel", { Parent = TabBtn, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 30, 0, 0), BackgroundTransparency = 1, Text = TabName, Font = Theme.Font, TextColor3 = Theme.TextDim, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })

        local Page = Create("ScrollingFrame", { Parent = ContentArea, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.Border, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false, ZIndex = 2 })
        Create("UIPadding", { Parent = Page, PaddingTop = UDim.new(0, 25), PaddingBottom = UDim.new(0, 25), PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 15) })
        
        local LeftCol = Create("Frame", { Parent = Page, Size = UDim2.new(0.5, -10, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, ZIndex = 2 })
        local RightCol = Create("Frame", { Parent = Page, Size = UDim2.new(0.5, -10, 1, 0), Position = UDim2.new(0.5, 10, 0, 0), BackgroundTransparency = 1, ZIndex = 2 })
        
        local LeftList = Create("UIListLayout", { Parent = LeftCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 15), VerticalAlignment = Enum.VerticalAlignment.Top })
        local RightList = Create("UIListLayout", { Parent = RightCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 15), VerticalAlignment = Enum.VerticalAlignment.Top })

        local function UpdateCanvas()
            local maxH = math.max(LeftList.AbsoluteContentSize.Y, RightList.AbsoluteContentSize.Y)
            Page.CanvasSize = UDim2.new(0, 0, 0, maxH + 40)
        end
        LeftList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)
        RightList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

        local function SelectTab()
            if Library.ActiveTab == TabBtn then return end
            if Library.ActiveTab then
                Tween(Library.ActiveTab.Label, {TextColor3 = Theme.TextDim}, 0.2)
                Tween(Library.ActiveTab.Indicator, {BackgroundTransparency = 1, Size = UDim2.new(0, 4, 0, 20), Position = UDim2.new(0, 0, 0.5, -10)}, 0.2)
                Library.ActiveTab.Page.Visible = false
            end
            Library.ActiveTab = {Btn = TabBtn, Label = TabLabel, Indicator = TabIndicator, Page = Page}
            Tween(TabLabel, {TextColor3 = Theme.Text}, 0.2)
            Tween(TabIndicator, {BackgroundTransparency = 0, Size = UDim2.new(0, 4, 0, 30), Position = UDim2.new(0, 0, 0.5, -15)}, 0.2)
            Page.Visible = true
        end

        TabBtn.MouseButton1Click:Connect(SelectTab)
        if FirstTab then FirstTab = false; SelectTab() end

        local TabAPI = {}
        local isLeft = true 

        function TabAPI:CreateSection(SectionName)
            local targetCol = isLeft and LeftCol or RightCol
            isLeft = not isLeft 

            local currentHeight = 52 
            local elementCount = 0
            local listPadding = 4

            local SectionFrame = Create("Frame", { Parent = targetCol, BackgroundColor3 = Theme.SectionBg, BackgroundTransparency = 0.45, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, currentHeight), ZIndex = 2 })
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = SectionFrame })
            Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = SectionFrame })

            local SectionHeader = Create("Frame", { Parent = SectionFrame, Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1, ZIndex = 2 })
            Create("TextLabel", { Parent = SectionHeader, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = SectionName, Font = Theme.FontBold, TextColor3 = Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
            Create("Frame", { Parent = SectionFrame, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0,0,0,35), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, ZIndex = 2 })

            local SectionContent = Create("Frame", { Parent = SectionFrame, Size = UDim2.new(1, 0, 1, -36), Position = UDim2.new(0, 0, 0, 36), BackgroundTransparency = 1, ZIndex = 2 })
            Create("UIListLayout", { Parent = SectionContent, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, listPadding) })
            Create("UIPadding", { Parent = SectionContent, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) })

            local function UpdateSectionSize()
                SectionFrame.Size = UDim2.new(1, 0, 0, currentHeight)
            end

            local function AddElementHeight(height)
                if elementCount > 0 then currentHeight = currentHeight + listPadding end
                currentHeight = currentHeight + height
                elementCount = elementCount + 1
                UpdateSectionSize()
            end

            local function ModifyRawHeight(amount)
                currentHeight = currentHeight + amount
                UpdateSectionSize()
            end

            local SectionAPI = {}

            function SectionAPI:CreateProfile()
                local ProfHeight = 60
                AddElementHeight(ProfHeight)
                
                local ProfFrame = Create("Frame", { Parent = SectionContent, Size = UDim2.new(1, 0, 0, ProfHeight), BackgroundTransparency = 1, ZIndex = 2 })
                local AvatarImg = Create("ImageLabel", { Parent = ProfFrame, Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 15, 0, 5), BackgroundColor3 = Theme.ElementBg, Image = "rbxthumb://type=AvatarHeadShot&id="..tostring(LocalPlayer.UserId).."&w=150&h=150", ZIndex = 2 })
                Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = AvatarImg })
                Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = AvatarImg })
                
                Create("TextLabel", { Parent = ProfFrame, Size = UDim2.new(1, -85, 0, 20), Position = UDim2.new(0, 75, 0, 10), BackgroundTransparency = 1, Text = LocalPlayer.DisplayName, Font = Theme.FontBold, TextColor3 = Theme.Text, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
                Create("TextLabel", { Parent = ProfFrame, Size = UDim2.new(1, -85, 0, 20), Position = UDim2.new(0, 75, 0, 30), BackgroundTransparency = 1, Text = "@" .. LocalPlayer.Name .. "  |  ID: " .. tostring(LocalPlayer.UserId), Font = Theme.Font, TextColor3 = Theme.TextDim, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
            end

            function SectionAPI:CreateLabel(text)
                local LblHeight = 20
                AddElementHeight(LblHeight)
                local LblFrame = Create("Frame", { Parent = SectionContent, Size = UDim2.new(1, 0, 0, LblHeight), BackgroundTransparency = 1, ZIndex = 2 })
                local TextLabel = Create("TextLabel", { Parent = LblFrame, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = text, Font = Theme.Font, TextColor3 = Theme.TextDim, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
                return TextLabel
            end
            
            function SectionAPI:CreateBigLabel(text)
                local LblHeight = 120
                AddElementHeight(LblHeight)
                local LblFrame = Create("Frame", { Parent = SectionContent, Size = UDim2.new(1, 0, 0, LblHeight), BackgroundTransparency = 1, ZIndex = 2 })
                local TextLabel = Create("TextLabel", { Parent = LblFrame, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = text, Font = Theme.Font, TextColor3 = Theme.TextDim, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 2, TextWrapped = true })
                return TextLabel
            end

            function SectionAPI:CreateToggle(opts)
                local Name = opts.Name or "Toggle"
                local Flag = opts.Flag or Name
                local State = Library.Flags[Flag]
                if State == nil then State = opts.Default or false end
                Library.Flags[Flag] = State

                local TogHeight = 40
                AddElementHeight(TogHeight)

                local TogFrame = Create("Frame", { Parent = SectionContent, Size = UDim2.new(1, 0, 0, TogHeight), BackgroundTransparency = 1, ZIndex = 2 })
                local Title = Create("TextLabel", { Parent = TogFrame, Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = Name, Font = Theme.Font, TextColor3 = State and Theme.Text or Theme.TextDim, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })

                local SwitchBtn = Create("TextButton", { Parent = TogFrame, Size = UDim2.new(0, 44, 0, 22), Position = UDim2.new(1, -59, 0.5, -11), BackgroundColor3 = State and Theme.Accent or Theme.ElementBg, Text = "", AutoButtonColor = false, ZIndex = 2 })
                Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchBtn })
                local SwitchStroke = Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = SwitchBtn, Transparency = State and 1 or 0 })

                local SwitchKnob = Create("Frame", { Parent = SwitchBtn, Size = UDim2.new(0, 16, 0, 16), Position = State and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255), ZIndex = 2 })
                Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchKnob })

                SwitchBtn.MouseButton1Click:Connect(function()
                    if opts.Exclusions then
                        for _, exc in ipairs(opts.Exclusions) do
                            if Library.Flags[exc] then
                                createNotification("Action Blocked", "Please disable '" .. exc .. "' first.")
                                return
                            end
                        end
                    end

                    State = not State
                    Library.Flags[Flag] = State
                    Tween(SwitchBtn, {BackgroundColor3 = State and Theme.Accent or Theme.ElementBg}, 0.2)
                    Tween(SwitchKnob, {Position = State and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, 0.2)
                    Tween(Title, {TextColor3 = State and Theme.Text or Theme.TextDim}, 0.2)
                    SwitchStroke.Transparency = State and 1 or 0
                    
                    SaveConfig()
                    if opts.Callback then opts.Callback(State) end
                end)
            end

            function SectionAPI:CreateSlider(opts)
                local Name = opts.Name or "Slider"
                local Flag = opts.Flag or Name
                local Min = opts.Min or 0
                local Max = opts.Max or 1
                local Default = opts.Default or Min
                local Decimals = opts.Decimals or 1
                
                local State = Library.Flags[Flag]
                if State == nil then State = Default end
                Library.Flags[Flag] = State

                local SliderHeight = 50
                AddElementHeight(SliderHeight)

                local SliderFrame = Create("Frame", { Parent = SectionContent, Size = UDim2.new(1, 0, 0, SliderHeight), BackgroundTransparency = 1, ZIndex = 2 })
                
                local Title = Create("TextLabel", { Parent = SliderFrame, Size = UDim2.new(1, -60, 0, 20), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = Name, Font = Theme.Font, TextColor3 = Theme.TextDim, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
                
                local ValueLabel = Create("TextLabel", { Parent = SliderFrame, Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -55, 0, 0), BackgroundTransparency = 1, Text = tostring(State), Font = Theme.FontBold, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 2 })

                local Track = Create("TextButton", { Parent = SliderFrame, Size = UDim2.new(1, -30, 0, 6), Position = UDim2.new(0, 15, 0, 25), BackgroundColor3 = Theme.ElementBg, AutoButtonColor = false, Text = "", ZIndex = 2 })
                Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })
                Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = Track })

                local fillPos = (State - Min) / (Max - Min)
                local Fill = Create("Frame", { Parent = Track, Size = UDim2.new(math.clamp(fillPos, 0, 1), 0, 1, 0), BackgroundColor3 = Theme.Accent, ZIndex = 2 })
                Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })

                local function UpdateSlider(input)
                    local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    local value = Min + ((Max - Min) * pos)
                    
                    local mult = 10 ^ Decimals
                    value = math.floor(value * mult + 0.5) / mult
                    
                    local clampedPos = (value - Min) / (Max - Min)
                    Tween(Fill, {Size = UDim2.new(clampedPos, 0, 1, 0)}, 0.1)
                    
                    ValueLabel.Text = tostring(value)
                    Library.Flags[Flag] = value
                    SaveConfig()
                    if opts.Callback then opts.Callback(value) end
                end

                local dragging = false
                Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        UpdateSlider(input)
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        UpdateSlider(input)
                    end
                end)
            end

            function SectionAPI:CreateTextBox(opts)
                local Name = opts.Name or "TextBox"
                local Flag = opts.Flag or Name
                local Placeholder = opts.Placeholder or ""
                local Callback = opts.Callback or function() end
                local State = Library.Flags[Flag]
                if State == nil then State = "" end
                Library.Flags[Flag] = State

                local BoxHeight = 55
                AddElementHeight(BoxHeight)

                local BoxFrame = Create("Frame", { Parent = SectionContent, Size = UDim2.new(1, 0, 0, BoxHeight), BackgroundTransparency = 1, ZIndex = 2 })
                local Title = Create("TextLabel", { Parent = BoxFrame, Size = UDim2.new(1, -24, 0, 15), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = Name, Font = Theme.Font, TextColor3 = Theme.TextDim, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
                
                local InputBox = Create("TextBox", { Parent = BoxFrame, Size = UDim2.new(1, -24, 0, 30), Position = UDim2.new(0, 12, 0, 20), BackgroundColor3 = Theme.ElementBg, Text = State, PlaceholderText = Placeholder, TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 13, ClearTextOnFocus = false, ZIndex = 2 })
                Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = InputBox })
                Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = InputBox })

                InputBox.FocusLost:Connect(function()
                    Library.Flags[Flag] = InputBox.Text
                    SaveConfig()
                    Callback(InputBox.Text)
                end)
            end

            function SectionAPI:CreateMultiSelect(opts)
                local Name = opts.Name or "Multi Select"
                local Flag = opts.Flag or Name
                local ItemList = opts.Items or SeedData
                local isSearchable = opts.Searchable
                local Dropped = false
                Library.Flags[Flag] = Library.Flags[Flag] or {}

                local DropBaseHeight = 40
                AddElementHeight(DropBaseHeight)

                local DropContainer = Create("Frame", { Parent = SectionContent, Size = UDim2.new(1, 0, 0, DropBaseHeight), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 2 })
                
                local DropBtn = Create("TextButton", { Parent = DropContainer, Size = UDim2.new(1, -24, 0, 32), Position = UDim2.new(0, 12, 0, 4), BackgroundColor3 = Theme.ElementBg, Text = "", AutoButtonColor = false, ZIndex = 2 })
                Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropBtn })
                Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = DropBtn })

                local SelectedText = Create("TextLabel", { Parent = DropBtn, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = Name, Font = Theme.FontBold, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
                local Icon = Create("TextLabel", { Parent = DropBtn, Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1, Text = "▼", Font = Theme.Font, TextColor3 = Theme.TextDim, TextSize = 11, ZIndex = 2 })

                local OptionsYOffset = 40
                local ExpandAmount = 200
                local SearchBox = nil

                if isSearchable then
                    OptionsYOffset = 75
                    ExpandAmount = 235
                    SearchBox = Create("TextBox", { Parent = DropContainer, Size = UDim2.new(1, -24, 0, 30), Position = UDim2.new(0, 12, 0, 40), BackgroundColor3 = Theme.MainBg, Text = "", PlaceholderText = "Search...", TextColor3 = Theme.Text, Font = Theme.Font, TextSize = 13, ZIndex = 2 })
                    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SearchBox })
                    Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = SearchBox })
                end

                local OptionsFrame = Create("ScrollingFrame", { Parent = DropContainer, Size = UDim2.new(1, -24, 0, 0), Position = UDim2.new(0, 12, 0, OptionsYOffset), BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 2 })
                Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = OptionsFrame })
                Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = OptionsFrame })
                local OptListLayout = Create("UIListLayout", { Parent = OptionsFrame })

                local ItemButtons = {}

                local function PopulateItems(list)
                    for _, child in ipairs(OptionsFrame:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    ItemButtons = {}
                    
                    for _, sData in ipairs(list) do
                        local btn = Create("TextButton", { Parent = OptionsFrame, Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 2 })
                        ItemButtons[sData.Name] = btn
                        
                        local isSelected = Library.Flags[Flag][sData.Name] or false
                        
                        local checkbox = Create("Frame", { Parent = btn, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 10, 0.5, -8), BackgroundColor3 = Theme.MainBg, ZIndex = 2 })
                        Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = checkbox })
                        Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = checkbox })
                        local checkFill = Create("Frame", { Parent = checkbox, Size = UDim2.new(1, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2), BackgroundColor3 = Theme.Accent, BackgroundTransparency = isSelected and 0 or 1, ZIndex = 2 })
                        Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = checkFill })

                        local nameLabel = Create("TextLabel", { Parent = btn, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 35, 0, 0), BackgroundTransparency = 1, Text = sData.Name, Font = Theme.FontBold, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
                        
                        if sData.Rarity then
                            Create("UIGradient", { Parent = nameLabel, Color = RarityColors[sData.Rarity] or RarityColors["Common"] })
                        end

                        btn.MouseEnter:Connect(function() Tween(btn, {BackgroundTransparency = 0.8}, 0.1) end)
                        btn.MouseLeave:Connect(function() Tween(btn, {BackgroundTransparency = 1}, 0.1) end)
                        
                        btn.MouseButton1Click:Connect(function()
                            isSelected = not isSelected
                            Library.Flags[Flag][sData.Name] = isSelected
                            Tween(checkFill, {BackgroundTransparency = isSelected and 0 or 1}, 0.1)
                            SaveConfig()
                        end)
                    end
                    OptionsFrame.CanvasSize = UDim2.new(0, 0, 0, #list * 35)
                end
                
                PopulateItems(ItemList)

                if SearchBox then
                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        local q = string.lower(SearchBox.Text)
                        local visCount = 0
                        for itemName, btn in pairs(ItemButtons) do
                            if q == "" or string.find(string.lower(itemName), q, 1, true) then
                                btn.Visible = true
                                visCount = visCount + 1
                            else
                                btn.Visible = false
                            end
                        end
                        OptionsFrame.CanvasSize = UDim2.new(0, 0, 0, visCount * 35)
                    end)
                end

                DropBtn.MouseButton1Click:Connect(function()
                    Dropped = not Dropped
                    if Dropped then
                        ModifyRawHeight(ExpandAmount)
                        Tween(DropContainer, {Size = UDim2.new(1, 0, 0, DropBaseHeight + ExpandAmount)}, 0.2)
                        Tween(OptionsFrame, {Size = UDim2.new(1, -24, 0, ExpandAmount - (isSearchable and 40 or 5))}, 0.2)
                        Tween(Icon, {Rotation = 180}, 0.2)
                    else
                        ModifyRawHeight(-ExpandAmount)
                        Tween(DropContainer, {Size = UDim2.new(1, 0, 0, DropBaseHeight)}, 0.2)
                        Tween(OptionsFrame, {Size = UDim2.new(1, -24, 0, 0)}, 0.2)
                        Tween(Icon, {Rotation = 0}, 0.2)
                    end
                end)
                
                return {
                    UpdateItems = function(self, newList)
                        PopulateItems(newList)
                    end
                }
            end
            
            function SectionAPI:CreateDynamicList(opts)
                local Name = opts.Name or "List"
                local ListHeight = opts.Height or 150
                
                AddElementHeight(ListHeight)
                
                local ListFrame = Create("Frame", { Parent = SectionContent, Size = UDim2.new(1, 0, 0, ListHeight), BackgroundTransparency = 1, ZIndex = 2 })
                local Title = Create("TextLabel", { Parent = ListFrame, Size = UDim2.new(1, -24, 0, 15), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = Name, Font = Theme.Font, TextColor3 = Theme.TextDim, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
                
                local Scroll = Create("ScrollingFrame", { Parent = ListFrame, Size = UDim2.new(1, -24, 1, -20), Position = UDim2.new(0, 12, 0, 20), BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,0), ZIndex = 2 })
                Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Scroll })
                Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = Scroll })
                Create("UIListLayout", { Parent = Scroll, SortOrder = Enum.SortOrder.LayoutOrder })
                
                local api = {}
                function api:Update(items)
                    for _, child in ipairs(Scroll:GetChildren()) do
                        if child:IsA("Frame") then child:Destroy() end
                    end
                    for i, item in ipairs(items) do
                        local itemFrame = Create("Frame", {Parent = Scroll, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, ClipsDescendants = true})
                        
                        if item.Type == "Button" then
                            local btn = Create("TextButton", { Parent = itemFrame, Size = UDim2.new(1, item.Buttons and -65 or 0, 0, 30), BackgroundTransparency = 1, Text = "  " .. item.Name, Font = Theme.FontBold, TextColor3 = Color3.fromRGB(255,255,255), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 2 })
                            btn.MouseEnter:Connect(function() Tween(btn, {BackgroundTransparency = 0.8}, 0.1) end)
                            btn.MouseLeave:Connect(function() Tween(btn, {BackgroundTransparency = 1}, 0.1) end)
                            btn.MouseButton1Click:Connect(item.Callback)
                        elseif item.Type == "Label" then
                            Create("TextLabel", { Parent = itemFrame, Size = UDim2.new(1, item.Buttons and -65 or 0, 0, 30), BackgroundTransparency = 1, Text = "  " .. item.Name, Font = Theme.FontBold, TextColor3 = Color3.fromRGB(255,255,255), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 })
                        end
                        
                        if item.Buttons then
                            local optBtn = Create("TextButton", { Parent = itemFrame, Size = UDim2.new(0, 60, 0, 24), Position = UDim2.new(1, -62, 0, 3), BackgroundColor3 = Theme.ElementHov, Text = "Options", Font = Theme.FontBold, TextColor3 = Theme.Text, TextSize = 11, ZIndex = 3 })
                            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = optBtn })
                            Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = optBtn })
                            
                            local btnContainer = Create("Frame", { Parent = itemFrame, Size = UDim2.new(1, 0, 0, #item.Buttons * 30), Position = UDim2.new(0, 0, 0, 30), BackgroundTransparency = 1, ZIndex = 2 })
                            Create("UIListLayout", { Parent = btnContainer, SortOrder = Enum.SortOrder.LayoutOrder })
                            
                            for bIdx, bData in ipairs(item.Buttons) do
                                local smBtn = Create("TextButton", { Parent = btnContainer, Size = UDim2.new(1, -20, 0, 26), Position = UDim2.new(0, 10, 0, 2), BackgroundColor3 = Theme.ElementHov, Text = bData.Text, Font = Theme.FontBold, TextColor3 = Theme.Accent, TextSize = 12, ZIndex = 3 })
                                Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = smBtn })
                                Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = smBtn })
                                smBtn.MouseButton1Click:Connect(bData.Callback)
                            end
                            
                            local isExpanded = false
                            optBtn.MouseButton1Click:Connect(function()
                                isExpanded = not isExpanded
                                if isExpanded then
                                    itemFrame.Size = UDim2.new(1, 0, 0, 30 + (#item.Buttons * 30))
                                    optBtn.Text = "Close"
                                else
                                    itemFrame.Size = UDim2.new(1, 0, 0, 30)
                                    optBtn.Text = "Options"
                                end
                            end)
                        end
                    end
                    Scroll.CanvasSize = UDim2.new(0, 0, 0, Scroll.UIListLayout.AbsoluteContentSize.Y)
                end
                
                return api
            end
            
            function SectionAPI:CreateButton(opts)
                local Name = opts.Name or "Button"
                local Callback = opts.Callback or function() end
                local BtnHeight = 45
                AddElementHeight(BtnHeight)

                local BtnFrame = Create("Frame", { Parent = SectionContent, Size = UDim2.new(1, 0, 0, BtnHeight), BackgroundTransparency = 1, ZIndex = 2 })
                local Button = Create("TextButton", { Parent = BtnFrame, Size = UDim2.new(1, -24, 0, 35), Position = UDim2.new(0, 12, 0, 5), BackgroundColor3 = Theme.ElementBg, Text = Name, Font = Theme.FontBold, TextColor3 = Theme.Text, TextSize = 13, AutoButtonColor = false, ZIndex = 2 })
                Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Button })
                
                Button.MouseButton1Click:Connect(Callback)
            end

            return SectionAPI
        end
        return TabAPI
    end
    
    if Library.Flags["CustomBackground"] and Library.Flags["CustomBackground"] ~= "" then
        local id = Library.Flags["CustomBackground"]
        if not string.find(id, "rbxassetid://") and not string.find(id, "rbxthumb://") then 
            id = "rbxassetid://" .. id
        end
        Library.BgImage.Image = id
    end
    
    return WindowAPI
end

-- ==============================================================================
-- MENU INITIALIZATION
-- ==============================================================================
local Window = Library:CreateWindow({ Title = "AXIOM", Subtitle = "HUB V1.0" })

local MainTab    = Window:CreateTab("Main Auto")
local EnvTab     = Window:CreateTab("Environment")
local EventsTab  = Window:CreateTab("Events")
local BuyTab     = Window:CreateTab("Purchases & Seeds")
local InfoTab    = Window:CreateTab("Information") 
local SettingsTab= Window:CreateTab("Settings")

-- ====== MAIN AUTO TAB ======
local SellSection = MainTab:CreateSection("Auto Sell")
SellSection:CreateToggle({ Name = "Auto Sell All Crops" })

local FarmSection = MainTab:CreateSection("Farming Automation")
FarmSection:CreateMultiSelect({ Name = "Plant Filter: Specific Seed", Flag = "Specific Plant Targets", Items = SeedData, Searchable = true })
FarmSection:CreateToggle({ Name = "Auto Place (By Specific Seed)", Exclusions = {"Auto Place (By Rarity)"} })

FarmSection:CreateMultiSelect({ Name = "Plant Filter: Rarity", Flag = "Rarity Plant Targets", Items = RarityList })
FarmSection:CreateToggle({ Name = "Auto Place (By Rarity)", Exclusions = {"Auto Place (By Specific Seed)"} })

local floorItems = {}
for i = 1, 4 do table.insert(floorItems, {Name = "Floor " .. i}) end

local UpgradeSection = MainTab:CreateSection("Auto Upgrade")
UpgradeSection:CreateToggle({ Name = "Auto Upgrade All Plants", Exclusions = {"Auto Upgrade Specific Plants"} })
UpgradeSection:CreateMultiSelect({ Name = "Upgrade Filter: Specific", Flag = "Specific Upgrade Targets", Items = SeedData, Searchable = true })
UpgradeSection:CreateToggle({ Name = "Auto Upgrade Specific Plants", Exclusions = {"Auto Upgrade All Plants"} })
UpgradeSection:CreateSlider({ Name = "Upgrade Speed (Delay)", Flag = "Upgrade Delay", Min = 0, Max = 2, Default = 0.5, Decimals = 2 })

local PlotUpgSec = MainTab:CreateSection("Plot & Luck Upgrades")
PlotUpgSec:CreateMultiSelect({ Name = "Select Plot Floors", Flag = "Plot Upg Floors", Items = floorItems, Searchable = false })
PlotUpgSec:CreateToggle({ Name = "Auto Upgrade Plot Yield" })
PlotUpgSec:CreateToggle({ Name = "Auto Upgrade Sprinkler Power" })
PlotUpgSec:CreateToggle({ Name = "Auto Upgrade Seed Luck" })

local ReplaceSec = MainTab:CreateSection("Crop Replacement")
local ReplaceList = ReplaceSec:CreateDynamicList({ Name = "Replaceable Candidates", Height = 150 })
ReplaceSec:CreateToggle({ Name = "Auto Replace Worst Crops" })

-- ====== ENVIRONMENT TAB ======
local FertOnlyData = {}
local SprayOnlyData = {}
for _, g in ipairs(GearData) do
    if string.find(g.Name, "Spray") then table.insert(SprayOnlyData, g)
    else table.insert(FertOnlyData, g) end
end

local FertSection = EnvTab:CreateSection("Fertilizer Automation")
local FertFloorUI = FertSection:CreateMultiSelect({ Name = "Select Floors", Flag = "Fert Floors", Items = floorItems, Searchable = false })
local FertPlantUI = FertSection:CreateMultiSelect({ Name = "Select Target Plants", Flag = "Fert Plants", Items = {}, Searchable = true })
FertSection:CreateMultiSelect({ Name = "Select Fertilizers", Flag = "Fertilizer Types", Items = FertOnlyData, Searchable = true })
FertSection:CreateToggle({ Name = "Enable Auto Fertilizer" })

local SpraySection = EnvTab:CreateSection("Spray Automation")
local SprayFloorUI = SpraySection:CreateMultiSelect({ Name = "Select Floors", Flag = "Spray Floors", Items = floorItems, Searchable = false })
local SprayPlantUI = SpraySection:CreateMultiSelect({ Name = "Select Target Plants", Flag = "Spray Plants", Items = {}, Searchable = true })
SpraySection:CreateMultiSelect({ Name = "Select Sprays", Flag = "Spray Types", Items = SprayOnlyData, Searchable = true })
SpraySection:CreateToggle({ Name = "Enable Auto Spray" })

-- ====== EVENTS TAB ======
local DefSection = EventsTab:CreateSection("Combat")
DefSection:CreateToggle({ Name = "Auto Kill Plant Enemy" })
DefSection:CreateToggle({ Name = "Auto Kill Boss" })

local LootSection = EventsTab:CreateSection("Looting")
LootSection:CreateToggle({ Name = "Auto Pickup Loot Drops" })

local WhackSec = EventsTab:CreateSection("Whack-a-Crop")
WhackSec:CreateToggle({ Name = "Auto Whack-a-Crop Event" })

local TokenSection = EventsTab:CreateSection("QueenBee")
TokenSection:CreateToggle({ Name = "Auto Collect Honeycomb" })
TokenSection:CreateToggle({ Name = "Auto Insert Honey Token" }) 

-- ====== PURCHASES & SEEDS TAB ======
local AutoBuySec = BuyTab:CreateSection("General Purchases")
AutoBuySec:CreateToggle({ Name = "Auto Buy Plot" }) 

local GearShopSec = BuyTab:CreateSection("Gear Automation")
GearShopSec:CreateMultiSelect({ Name = "Select Target Gear", Flag = "Target Gear List", Items = GearData, Searchable = true })
GearShopSec:CreateToggle({ Name = "Auto Buy Selected Gear" })

local EggShopSec = BuyTab:CreateSection("Egg Purchasing")
EggShopSec:CreateToggle({ Name = "Auto Buy Egg (Common)" }) 
EggShopSec:CreateToggle({ Name = "Auto Buy Egg (Rare)" }) 
EggShopSec:CreateToggle({ Name = "Auto Buy Egg (Epic)" }) 

local SeedSection = BuyTab:CreateSection("Seed Manager")
SeedSection:CreateMultiSelect({ Name = "Select Target Seeds to Roll", Flag = "Target Seeds List", Items = SeedData, Searchable = true })
SeedSection:CreateToggle({ Name = "Wait for Cash to Buy Seed", Default = true })
SeedSection:CreateToggle({ Name = "Auto Upcycle Worst Crop (Lv 30 Max)" })
SeedSection:CreateToggle({ Name = "Auto Roll & Buy Targets" })
SeedSection:CreateToggle({ Name = "Auto Buy ANY Transcendent Seed" })

local DiscardSec = BuyTab:CreateSection("Auto Discard Seeds")
DiscardSec:CreateMultiSelect({ Name = "Discard Filter: Specific", Flag = "Discard Specific Seeds", Items = SeedData, Searchable = true })
DiscardSec:CreateMultiSelect({ Name = "Discard Filter: Rarity", Flag = "Discard Rarity", Items = RarityList })
DiscardSec:CreateToggle({ Name = "Auto Discard Seeds" })

-- ====== INFO TAB & LIVE DATA ======
local UserSec = InfoTab:CreateSection("Player Profile")
UserSec:CreateProfile()
local PlayTimeLbl = UserSec:CreateLabel("Session Time: 00:00:00")

local GameSec = InfoTab:CreateSection("Live Game Data")
local CashLbl = GameSec:CreateLabel("Cash: Scanning...")
local CropsLbl = GameSec:CreateLabel("Planted Crops: Scanning...")

local BestPlantsSec = InfoTab:CreateSection("Top Paying Plants (Plots)")
local BestPlantsList = BestPlantsSec:CreateDynamicList({ Name = "Click to select...", Height = 200 })

local ReplacedCropsSec = InfoTab:CreateSection("Recently Replaced Crops")
local ReplacedCropsList = ReplacedCropsSec:CreateDynamicList({ Name = "Actions...", Height = 150 })

local PurchasedSeedsSec = InfoTab:CreateSection("Seeds Purchased (Session)")
local PurchasedSeedsList = PurchasedSeedsSec:CreateDynamicList({ Name = "List of bought seeds...", Height = 150 })
_G.PurchasedSeedsListApi = PurchasedSeedsList

local BestToolsSec = InfoTab:CreateSection("Available Tools")
local BestToolsList = BestToolsSec:CreateDynamicList({ Name = "Click to equip tool...", Height = 150 })

local BestSeedsSec = InfoTab:CreateSection("Top Inventory Seeds")
local BestSeedsList = BestSeedsSec:CreateDynamicList({ Name = "Click to equip seed...", Height = 150 })

-- ====== SETTINGS TAB ======
local AppearanceSection = SettingsTab:CreateSection("UI Background")

AppearanceSection:CreateButton({ 
    Name = "Default Background (None)", 
    Callback = function() 
        Library.Flags["CustomBackground"] = ""
        SaveConfig()
        if Library.BgImage then Library.BgImage.Image = "" end
    end 
})

AppearanceSection:CreateButton({ 
    Name = "Emilia Preset", 
    Callback = function() 
        local id = "rbxassetid://126923601510884"
        Library.Flags["CustomBackground"] = id
        SaveConfig()
        if Library.BgImage then Library.BgImage.Image = id end
    end 
})

AppearanceSection:CreateTextBox({
    Name = "Custom Background ID",
    Flag = "CustomBackground",
    Placeholder = "Enter Asset ID (e.g. 126923601510884)",
    Callback = function(val)
        local id = val
        if id ~= "" and not string.find(id, "rbxassetid://") and not string.find(id, "rbxthumb://") then
            id = "rbxassetid://" .. id
        end
        Library.Flags["CustomBackground"] = id
        SaveConfig()
        if Library.BgImage then Library.BgImage.Image = id end
    end
})

local PlayerMods = SettingsTab:CreateSection("Local Player")
PlayerMods:CreateSlider({Name = "WalkSpeed", Flag = "WalkSpeed", Min = 16, Max = 150, Default = 16, Decimals = 0})
PlayerMods:CreateSlider({Name = "JumpPower", Flag = "JumpPower", Min = 50, Max = 200, Default = 50, Decimals = 0})
PlayerMods:CreateSlider({Name = "Field of View", Flag = "FOV", Min = 70, Max = 120, Default = 70, Decimals = 0})
PlayerMods:CreateToggle({Name = "Anti-AFK", Default = true})

local UtilitySec = SettingsTab:CreateSection("Utilities")
UtilitySec:CreateButton({Name = "Clear All Notifications", Callback = function() 
    for key, notif in pairs(ActiveNotifications) do
        if notif.Frame then notif.Frame:Destroy() end
        ActiveNotifications[key] = nil
    end
end})
UtilitySec:CreateButton({Name = "Rejoin Server", Callback = function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end})

local AlertSection = SettingsTab:CreateSection("Logs & Alerts")
AlertSection:CreateToggle({ Name = "Screen Notifications", Default = true })

local PerfSection = SettingsTab:CreateSection("Performance")
PerfSection:CreateToggle({ 
    Name = "Potato Graphics", 
    Callback = function(state)
        if state then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then 
                    v.Material = Enum.Material.SmoothPlastic
                elseif v:IsA("Decal") or v:IsA("Texture") then 
                    v.Transparency = 1 
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                    v.Enabled = false
                end
            end
            game.Lighting.GlobalShadows = false
            game.Lighting.FogEnd = 9e9
            for _, effect in pairs(game.Lighting:GetChildren()) do
                if effect:IsA("PostEffect") or effect:IsA("Atmosphere") then
                    effect.Enabled = false
                end
            end
        end
    end 
})

PerfSection:CreateButton({ Name = "Unload GUI", Callback = function() 
    isUnloaded = true 
    if UI_PARENT:FindFirstChild("AxiomHub_Core") then UI_PARENT.AxiomHub_Core:Destroy() end
end })

-- ==============================================================================
-- RUNTIME BACKGROUND ENGINE 
-- ==============================================================================

task.spawn(function()
    while not isUnloaded do
        cachedPlot = getPlayerPlot()
        local runtime = os.time() - Library.SessionStart
        local hours = math.floor(runtime / 3600)
        local minutes = math.floor((runtime % 3600) / 60)
        local seconds = runtime % 60
        PlayTimeLbl.Text = string.format("Session Time: %02d:%02d:%02d", hours, minutes, seconds)

        pcall(function()
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            if leaderstats then
                local cash = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Coins")
                if cash then CashLbl.Text = "Cash: $" .. tostring(cash.Value) end
            end
            
            if Library.Flags["WalkSpeed"] and Library.Flags["WalkSpeed"] > 16 then
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.WalkSpeed = Library.Flags["WalkSpeed"]
                end
            end
            if Library.Flags["JumpPower"] and Library.Flags["JumpPower"] > 50 then
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.JumpPower = Library.Flags["JumpPower"]
                end
            end
            if Library.Flags["FOV"] and Library.Flags["FOV"] > 70 then
                workspace.CurrentCamera.FieldOfView = Library.Flags["FOV"]
            end
        end)
        
        task.wait(1)
    end
end)

-- ==============================================================================
-- AUTO SELL
-- ==============================================================================
task.spawn(function()
    while not isUnloaded do
        if Library.Flags["Auto Sell All Crops"] == true then
            pcall(function()
                local rsRemotes = ReplicatedStorage:FindFirstChild("Remotes")
                if rsRemotes and rsRemotes:FindFirstChild("SellCrates") then
                    rsRemotes.SellCrates:FireServer()
                end
            end)
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

-- ==============================================================================
-- GLOBAL UPGRADES
-- ==============================================================================
task.spawn(function()
    while not isUnloaded do
        if Library.Flags["Auto Upgrade Seed Luck"] then
            pcall(function()
                local rsRemotes = ReplicatedStorage:FindFirstChild("Remotes")
                if rsRemotes and rsRemotes:FindFirstChild("UpgradeSeedLuck") then
                    rsRemotes.UpgradeSeedLuck:InvokeServer()
                end
            end)
            task.wait(1)
        else
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    while not isUnloaded do
        local upgYield = Library.Flags["Auto Upgrade Plot Yield"]
        local upgPower = Library.Flags["Auto Upgrade Sprinkler Power"]
        local activeFloors = Library.Flags["Plot Upg Floors"] or {}
        
        if (upgYield or upgPower) then
            pcall(function()
                local rsRemotes = ReplicatedStorage:FindFirstChild("Remotes")
                if rsRemotes and rsRemotes:FindFirstChild("PlotUpgradeTransaction") then
                    for i = 1, 4 do
                        local floorName = "Floor " .. i
                        local serverFloorName = "Floor" .. i
                        if activeFloors[floorName] then
                            if upgYield then
                                rsRemotes.PlotUpgradeTransaction:InvokeServer("ExtraYield", serverFloorName)
                                task.wait(0.2)
                            end
                            if upgPower then
                                rsRemotes.PlotUpgradeTransaction:InvokeServer("ExtraPower", serverFloorName)
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end)
            task.wait(1)
        else
            task.wait(0.5)
        end
    end
end)

-- ==============================================================================
-- CROP REPLACEMENT ENGINE & FAST UI UPDATE
-- ==============================================================================
task.spawn(function()
    while not isUnloaded do
        pcall(function()
            if cachedPlot then
                local bestSeedTool = nil
                local bestSeedRank = 0
                local bestSeedName = ""
                
                local char = LocalPlayer.Character
                local items = LocalPlayer.Backpack:GetChildren()
                if char then for _, v in ipairs(char:GetChildren()) do table.insert(items, v) end end
                
                for _, item in ipairs(items) do
                    if item:IsA("Tool") then
                        local cName = item.Name:gsub(" Seed", ""):gsub(" Shooter", ""):gsub("%s*%(x%d+%)", "")
                        cName = cName:match("^%s*(.-)%s*$") or cName
                        local rank = GetPlantRank(cName)
                        if rank > bestSeedRank then
                            bestSeedRank = rank
                            bestSeedTool = item
                            bestSeedName = cName
                        end
                    end
                end
                
                local candidates = {}
                for _, plotFolder in ipairs(cachedPlot:GetDescendants()) do
                    if (plotFolder:IsA("Folder") or plotFolder:IsA("Model")) and plotFolder.Name == "FarmPlot" then
                        
                        local dirtCount = 0
                        local avgX = 0
                        local avgZ = 0
                        for _, child in ipairs(plotFolder:GetChildren()) do
                            if child:IsA("Model") then
                                local d = child:FindFirstChild("Dirt")
                                if d and d:IsA("BasePart") then
                                    dirtCount = dirtCount + 1
                                    avgX = avgX + d.Position.X
                                    avgZ = avgZ + d.Position.Z
                                end
                            end
                        end
                        
                        local centerX = dirtCount > 0 and avgX/dirtCount or 0
                        local centerZ = dirtCount > 0 and avgZ/dirtCount or 0
                        
                        for _, child in ipairs(plotFolder:GetChildren()) do
                            if child:IsA("Model") then
                                local dirt = child:FindFirstChild("Dirt")
                                if dirt and dirt:GetAttribute("PlantName") then
                                    local pName = dirt:GetAttribute("PlantName")
                                    local pRank = GetPlantRank(pName)
                                    
                                    if pRank < bestSeedRank and pName ~= "Garden Golem" then
                                        local dist = math.sqrt((dirt.Position.X - centerX)^2 + (dirt.Position.Z - centerZ)^2)
                                        table.insert(candidates, {dirt = dirt, rank = pRank, name = pName, dist = dist})
                                    end
                                end
                            end
                        end
                    end
                end
                
                table.sort(candidates, function(a, b) 
                    if a.rank == b.rank then
                        return a.dist > b.dist 
                    end
                    return a.rank < b.rank 
                end)
                
                local replaceUI = {}
                for i = 1, math.min(15, #candidates) do
                    local cand = candidates[i]
                    table.insert(replaceUI, {
                        Type = "Button",
                        Name = cand.name .. " -> " .. bestSeedName,
                        Callback = function()
                            pcall(function()
                                local rsRemotes = ReplicatedStorage:FindFirstChild("Remotes")
                                if rsRemotes and rsRemotes:FindFirstChild("RemovePlant") then
                                    rsRemotes.RemovePlant:FireServer(cand.dirt)
                                    task.wait(0.3)
                                    local hum = char and char:FindFirstChild("Humanoid")
                                    if hum and bestSeedTool.Parent ~= char then hum:EquipTool(bestSeedTool) end
                                    task.wait(0.2)
                                    if rsRemotes:FindFirstChild("PlantSeed") then
                                        rsRemotes.PlantSeed:FireServer(cand.dirt)
                                        createNotification("Crop Replaced", "Replaced " .. cand.name .. " with " .. bestSeedName)
                                        table.insert(Library.ReplacedCrops, 1, {name = bestSeedName, old = cand.name, dirt = cand.dirt})
                                        Library.UpcycleUpgrades[cand.dirt] = true
                                    end
                                end
                            end)
                        end
                    })
                end
                if #replaceUI == 0 then table.insert(replaceUI, {Type = "Label", Name = "No replacements needed."}) end
                ReplaceList:Update(replaceUI)
                
                if Library.Flags["Auto Replace Worst Crops"] and #candidates > 0 and bestSeedTool then
                    local cand = candidates[1]
                    local rsRemotes = ReplicatedStorage:FindFirstChild("Remotes")
                    if rsRemotes and rsRemotes:FindFirstChild("RemovePlant") then
                        rsRemotes.RemovePlant:FireServer(cand.dirt)
                        task.wait(0.3)
                        local hum = char and char:FindFirstChild("Humanoid")
                        if hum and bestSeedTool.Parent ~= char then hum:EquipTool(bestSeedTool) end
                        task.wait(0.2)
                        if rsRemotes:FindFirstChild("PlantSeed") then
                            rsRemotes.PlantSeed:FireServer(cand.dirt)
                            createNotification("Auto Replaced", cand.name .. " -> " .. bestSeedName)
                            table.insert(Library.ReplacedCrops, 1, {name = bestSeedName, old = cand.name, dirt = cand.dirt})
                            Library.UpcycleUpgrades[cand.dirt] = true
                        end
                    end
                end
                
                local replacedUI = {}
                for i = 1, math.min(10, #Library.ReplacedCrops) do
                    local rc = Library.ReplacedCrops[i]
                    local displayId = rc.name .. " | Lvl 1 | None | $0" 
                    table.insert(replacedUI, {
                        Type = "Label",
                        Name = rc.old .. " -> " .. rc.name,
                        Buttons = {
                            {Text = "TP", Callback = function()
                                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and rc.dirt then
                                    LocalPlayer.Character.HumanoidRootPart.CFrame = rc.dirt.CFrame + Vector3.new(0, 4, 0)
                                end
                            end},
                            {Text = "Spray", Callback = function()
                                local currentSpray = Library.Flags["Spray Types"] or {}
                                local sprayName = ""
                                for k, v in pairs(currentSpray) do if v then sprayName = k break end end
                                if sprayName ~= "" then
                                    Library.Flags["PlantOverrides"][displayId] = {Spray = sprayName}
                                    SaveConfig()
                                    createNotification("Override Set", "Locked " .. sprayName .. " for " .. rc.name)
                                else
                                    createNotification("Error", "Select a spray in the Environment tab first.")
                                end
                            end},
                            {Text = "Fert", Callback = function()
                                local currentFert = Library.Flags["Fertilizer Types"] or {}
                                local fertName = ""
                                for k, v in pairs(currentFert) do if v then fertName = k break end end
                                if fertName ~= "" then
                                    Library.Flags["PlantOverrides"][displayId] = Library.Flags["PlantOverrides"][displayId] or {}
                                    Library.Flags["PlantOverrides"][displayId].Fert = fertName
                                    SaveConfig()
                                    createNotification("Override Set", "Locked " .. fertName .. " for " .. rc.name)
                                else
                                    createNotification("Error", "Select a fertilizer in the Environment tab first.")
                                end
                            end}
                        }
                    })
                end
                if #replacedUI == 0 then table.insert(replacedUI, {Type = "Label", Name = "No crops replaced recently."}) end
                ReplacedCropsList:Update(replacedUI)
            end
        end)
        
        task.wait(5)
    end
end)

-- ==============================================================================
-- [ INFO TAB & ENVIRONMENT SYNC ENGINE ] - EVERY 5 SECONDS (Fert/Spray), 30 SECONDS (Info)
-- ==============================================================================
local infoUpdateCounter = 0

task.spawn(function()
    while not isUnloaded do
        pcall(function()
            if cachedPlot then
                local currentEnvPlants = {}
                for _, plotFolder in ipairs(cachedPlot:GetDescendants()) do
                    if (plotFolder:IsA("Folder") or plotFolder:IsA("Model")) and plotFolder.Name == "FarmPlot" then
                        local parentName = plotFolder.Parent and plotFolder.Parent.Name or ""
                        local floorNum = parentName:match("^Floor(%d+)$") or 1
                        
                        for _, child in ipairs(plotFolder:GetChildren()) do
                            if child:IsA("Model") then
                                local dirt = child:FindFirstChild("Dirt")
                                if dirt and dirt:GetAttribute("PlantName") then
                                    local pName = dirt:GetAttribute("PlantName")
                                    local pLevel = dirt:GetAttribute("PlantLevel") or 1
                                    local pMut = dirt:GetAttribute("PlantMutation") or "None"
                                    local income = GetPlantIncome(pName, pMut, pLevel)
                                    
                                    local uniqueId = pName .. " | Lvl " .. pLevel .. " | " .. pMut
                                    table.insert(currentEnvPlants, {Name = uniqueId, Floor = tonumber(floorNum), Income = income, FullDisplay = uniqueId .. " | $" .. FormatNumber(income)})
                                end
                            end
                        end
                    end
                end
                
                table.sort(currentEnvPlants, function(a, b) return a.Income > b.Income end)
                local newFertItems = {}
                local newSprayItems = {}
                
                local activeFertFloors = Library.Flags["Fert Floors"] or {}
                local activeSprayFloors = Library.Flags["Spray Floors"] or {}
                
                for _, plant in ipairs(currentEnvPlants) do
                    if activeFertFloors["Floor " .. plant.Floor] then table.insert(newFertItems, {Name = plant.FullDisplay}) end
                    if activeSprayFloors["Floor " .. plant.Floor] then table.insert(newSprayItems, {Name = plant.FullDisplay}) end
                end
                
                FertPlantUI:UpdateItems(newFertItems)
                SprayPlantUI:UpdateItems(newSprayItems)
            end
        end)
        
        if infoUpdateCounter % 15 == 0 then
            pcall(function()
                if cachedPlot then
                    local plantCount = 0
                    local plantedList = {}
                    for _, plotFolder in ipairs(cachedPlot:GetDescendants()) do
                        if (plotFolder:IsA("Folder") or plotFolder:IsA("Model")) and plotFolder.Name == "FarmPlot" then
                            for _, child in ipairs(plotFolder:GetChildren()) do
                                if child:IsA("Model") then
                                    local dirt = child:FindFirstChild("Dirt")
                                    if dirt and dirt:GetAttribute("PlantName") then
                                        plantCount = plantCount + 1
                                        local pName = dirt:GetAttribute("PlantName")
                                        local pLevel = dirt:GetAttribute("PlantLevel") or 1
                                        local pMut = dirt:GetAttribute("PlantMutation") or "None"
                                        local income = GetPlantIncome(pName, pMut, pLevel)
                                        
                                        local fertEnd = dirt:GetAttribute("FertilizerBoostEndTimestamp") or 0
                                        local pFert = (dirt:GetAttribute("Fertilized") == true or fertEnd > os.time()) and "Fertilized" or "Raw"
                                        
                                        table.insert(plantedList, {
                                            name = pName,
                                            level = pLevel,
                                            mut = pMut,
                                            fert = pFert,
                                            income = income,
                                            dirt = dirt
                                        })
                                    end
                                end
                            end
                        end
                    end
                    
                    CropsLbl.Text = "Planted Crops: " .. tostring(plantCount)
                    table.sort(plantedList, function(a, b) return a.income > b.income end)
                    
                    local infoPlants = {}
                    for i = 1, math.min(15, #plantedList) do
                        local p = plantedList[i]
                        local label = i .. ". " .. p.name .. " [Lv" .. p.level .. "] | " .. p.mut .. " | " .. p.fert .. " ($" .. FormatNumber(p.income) .. "/u)"
                        local uniqueId = p.name .. " | Lvl " .. p.level .. " | " .. p.mut .. " | $" .. FormatNumber(p.income)
                        
                        table.insert(infoPlants, {
                            Type = "Label", 
                            Name = label,
                            Buttons = {
                                {Text = "TP to Plant", Callback = function()
                                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and p.dirt then
                                        LocalPlayer.Character.HumanoidRootPart.CFrame = p.dirt.CFrame + Vector3.new(0, 4, 0)
                                    end
                                end},
                                {Text = "Priority Upgrade", Callback = function()
                                    Library.Flags["Specific Upgrade Targets"] = Library.Flags["Specific Upgrade Targets"] or {}
                                    Library.Flags["Specific Upgrade Targets"][p.name] = true
                                    Library.Flags["Auto Upgrade Specific Plants"] = true
                                    SaveConfig()
                                    createNotification("Prioritized", "Now auto-upgrading: " .. p.name)
                                end},
                                {Text = "Priority Fertilizer", Callback = function()
                                    Library.Flags["Fert Plants"] = Library.Flags["Fert Plants"] or {}
                                    Library.Flags["Fert Plants"][uniqueId] = true
                                    Library.Flags["Enable Auto Fertilizer"] = true
                                    SaveConfig()
                                    createNotification("Prioritized", "Now auto-fertilizing: " .. p.name)
                                end},
                                {Text = "Override Spray", Callback = function()
                                    local currentSpray = Library.Flags["Spray Types"] or {}
                                    local sprayName = ""
                                    for k, v in pairs(currentSpray) do if v then sprayName = k break end end
                                    if sprayName ~= "" then
                                        Library.Flags["PlantOverrides"][uniqueId] = {Spray = sprayName}
                                        SaveConfig()
                                        createNotification("Override Set", "Locked " .. sprayName .. " for " .. p.name)
                                    else
                                        createNotification("Error", "Select a spray in the Environment tab first.")
                                    end
                                end},
                                {Text = "Override Fert", Callback = function()
                                    local currentFert = Library.Flags["Fertilizer Types"] or {}
                                    local fertName = ""
                                    for k, v in pairs(currentFert) do if v then fertName = k break end end
                                    if fertName ~= "" then
                                        Library.Flags["PlantOverrides"][uniqueId] = Library.Flags["PlantOverrides"][uniqueId] or {}
                                        Library.Flags["PlantOverrides"][uniqueId].Fert = fertName
                                        SaveConfig()
                                        createNotification("Override Set", "Locked " .. fertName .. " for " .. p.name)
                                    else
                                        createNotification("Error", "Select a fertilizer in the Environment tab first.")
                                    end
                                end}
                            }
                        })
                    end
                    if #infoPlants == 0 then table.insert(infoPlants, {Type = "Label", Name = "No plants found."}) end
                    BestPlantsList:Update(infoPlants)
                end
            end)
            
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local availableSprays = {}
                    local availableFerts = {}
                    local availableSeeds = {}
                    
                    local items = LocalPlayer.Backpack:GetChildren()
                    for _, v in ipairs(char:GetChildren()) do table.insert(items, v) end
                    
                    for _, item in ipairs(items) do
                        if item:IsA("Tool") then
                            local cName = item.Name:gsub("%s*%(x%d+%)", "")
                            if SprayRanks[cName] then
                                table.insert(availableSprays, {name = cName, raw = item.Name, rank = SprayRanks[cName]})
                            elseif FertRanks[cName] then
                                table.insert(availableFerts, {name = cName, raw = item.Name, rank = FertRanks[cName]})
                            else
                                local sName = cName:gsub(" Seed", ""):gsub(" Shooter", "")
                                for _, sd in ipairs(SeedData) do
                                    if sd.Name == sName then
                                        table.insert(availableSeeds, {name = sName, raw = item.Name, rank = sd.Rank})
                                        break
                                    end
                                end
                            end
                        end
                    end
                    
                    table.sort(availableSprays, function(a, b) return a.rank > b.rank end)
                    table.sort(availableFerts, function(a, b) return a.rank > b.rank end)
                    table.sort(availableSeeds, function(a, b) return a.rank > b.rank end)
                    
                    local toolUI = {}
                    local seenTools = {}
                    for _, t in ipairs(availableSprays) do
                        if not seenTools[t.name] then
                            seenTools[t.name] = true
                            table.insert(toolUI, {Type = "Button", Name = t.name, Callback = function() EquipItemByName(t.name) end})
                        end
                    end
                    for _, t in ipairs(availableFerts) do
                        if not seenTools[t.name] then
                            seenTools[t.name] = true
                            table.insert(toolUI, {Type = "Button", Name = t.name, Callback = function() EquipItemByName(t.name) end})
                        end
                    end
                    if #toolUI == 0 then table.insert(toolUI, {Type = "Label", Name = "No tools found."}) end
                    BestToolsList:Update(toolUI)
                    
                    local seedUI = {}
                    local seenSeeds = {}
                    local count = 0
                    for _, s in ipairs(availableSeeds) do
                        if not seenSeeds[s.name] then
                            seenSeeds[s.name] = true
                            count = count + 1
                            table.insert(seedUI, {Type = "Button", Name = s.name, Callback = function() EquipItemByName(s.name) end})
                            if count >= 15 then break end
                        end
                    end
                    if #seedUI == 0 then table.insert(seedUI, {Type = "Label", Name = "No valid seeds found."}) end
                    BestSeedsList:Update(seedUI)
                end
            end)
            
            pcall(function()
                local pSeeds = {}
                for sName, count in pairs(Library.PurchasedSeeds) do
                    table.insert(pSeeds, {name = sName, count = count})
                end
                table.sort(pSeeds, function(a, b) return a.count > b.count end)
                
                local pUI = {}
                for i=1, math.min(15, #pSeeds) do
                    table.insert(pUI, {Type = "Label", Name = tostring(pSeeds[i].count) .. "x " .. pSeeds[i].name})
                end
                if #pUI == 0 then table.insert(pUI, {Type = "Label", Name = "No seeds purchased yet."}) end
                PurchasedSeedsList:Update(pUI)
            end)
        end
        infoUpdateCounter = infoUpdateCounter + 1
        
        task.wait(2)
    end
end)

task.spawn(function()
    while not isUnloaded do
        local useFert = Library.Flags["Enable Auto Fertilizer"]
        local useSpray = Library.Flags["Enable Auto Spray"]
        
        if (useFert or useSpray) and cachedPlot then
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                local hum = char:FindFirstChild("Humanoid")
                if not hum then return end
                
                local availableSprays = {}
                local availableFerts = {}
                
                local items = LocalPlayer.Backpack:GetChildren()
                for _, v in ipairs(char:GetChildren()) do table.insert(items, v) end
                
                for _, item in ipairs(items) do
                    if item:IsA("Tool") then
                        local cName = item.Name:gsub("%s*%(x%d+%)", "")
                        if SprayRanks[cName] then
                            table.insert(availableSprays, {tool = item, name = cName, rank = SprayRanks[cName]})
                        elseif FertRanks[cName] then
                            table.insert(availableFerts, {tool = item, name = cName, rank = FertRanks[cName]})
                        end
                    end
                end
                
                table.sort(availableSprays, function(a, b) return a.rank > b.rank end)
                table.sort(availableFerts, function(a, b) return a.rank > b.rank end)
                
                local plantsToSpray = {}
                local plantsToFert = {}
                
                local targetSprayList = Library.Flags["Spray Plants"] or {}
                local targetFertList = Library.Flags["Fert Plants"] or {}
                
                local allowFerts = Library.Flags["Fertilizer Types"] or {}
                local allowSprays = Library.Flags["Spray Types"] or {}
                local overrides = Library.Flags["PlantOverrides"] or {}
                
                for _, plotFolder in ipairs(cachedPlot:GetDescendants()) do
                    if (plotFolder:IsA("Folder") or plotFolder:IsA("Model")) and plotFolder.Name == "FarmPlot" then
                        for _, child in ipairs(plotFolder:GetChildren()) do
                            local dirt = child:FindFirstChild("Dirt")
                            if dirt and dirt:IsA("BasePart") then
                                local pName = dirt:GetAttribute("PlantName")
                                local pLevel = dirt:GetAttribute("PlantLevel") or 1
                                local pMut = dirt:GetAttribute("PlantMutation") or "None"
                                local income = GetPlantIncome(pName, pMut, pLevel)
                                
                                if pName then
                                    local displayId = pName .. " | Lvl " .. pLevel .. " | " .. pMut .. " | $" .. FormatNumber(income)
                                    local shortId = pName .. " | Lvl " .. pLevel .. " | " .. pMut 
                                    
                                    local isMutated = pMut and pMut ~= "Normal" and pMut ~= "None"
                                    local fertEnd = dirt:GetAttribute("FertilizerBoostEndTimestamp") or 0
                                    local isFertilized = dirt:GetAttribute("Fertilized") == true or fertEnd > os.time()
                                    
                                    if useSpray and not isMutated and targetSprayList[displayId] then
                                        table.insert(plantsToSpray, {dirt = dirt, income = income, id = shortId})
                                    end
                                    if useFert and not isFertilized and targetFertList[displayId] then
                                        table.insert(plantsToFert, {dirt = dirt, income = income, id = shortId})
                                    end
                                end
                            end
                        end
                    end
                end
                
                table.sort(plantsToSpray, function(a, b) return a.income > b.income end)
                table.sort(plantsToFert, function(a, b) return a.income > b.income end)
                
                if useSpray and #plantsToSpray > 0 then
                    local bestPlantData = plantsToSpray[1]
                    local bestPlant = bestPlantData.dirt
                    local chosenSpray = nil
                    
                    if overrides[bestPlantData.id] and overrides[bestPlantData.id].Spray then
                        for _, spray in ipairs(availableSprays) do
                            if spray.name == overrides[bestPlantData.id].Spray then
                                chosenSpray = spray.tool; break
                            end
                        end
                    end
                    
                    if not chosenSpray then
                        for _, spray in ipairs(availableSprays) do
                            if allowSprays[spray.name] then chosenSpray = spray.tool; break end
                        end
                    end
                    
                    if chosenSpray then
                        if chosenSpray.Parent ~= char then hum:EquipTool(chosenSpray) task.wait(0.2) end
                        local sprayRemote = Remotes:FindFirstChild("UseSpray")
                        if sprayRemote then
                            sprayRemote:FireServer(bestPlant)
                            createNotification("Plant Sprayed", "Sprayed " .. tostring(bestPlant:GetAttribute("PlantName")))
                            task.wait(0.4)
                        end
                    end
                end
                
                if useFert and #plantsToFert > 0 then
                    local bestPlantData = plantsToFert[1]
                    local bestPlant = bestPlantData.dirt
                    local chosenFert = nil
                    
                    if overrides[bestPlantData.id] and overrides[bestPlantData.id].Fert then
                        for _, fert in ipairs(availableFerts) do
                            if fert.name == overrides[bestPlantData.id].Fert then
                                chosenFert = fert.tool; break
                            end
                        end
                    end
                    
                    if not chosenFert then
                        for _, fert in ipairs(availableFerts) do
                            if allowFerts[fert.name] then chosenFert = fert.tool; break end
                        end
                    end
                    
                    if chosenFert then
                        if chosenFert.Parent ~= char then hum:EquipTool(chosenFert) task.wait(0.2) end
                        local fertRemote = Remotes:FindFirstChild("UseFertilizer")
                        if fertRemote then
                            fertRemote:FireServer(bestPlant)
                            createNotification("Plant Fertilized", "Fertilized " .. tostring(bestPlant:GetAttribute("PlantName")))
                            task.wait(0.4)
                        end
                    end
                end
                
            end)
            task.wait(1)
        else
            task.wait(0.5)
        end
    end
end)

-- ==============================================================================
-- [ DO NOT EDIT OR TOUCH THIS ] - END OF ENGINE PROTECTION SECTION
-- ==============================================================================
local isBuyingEgg = false
local lockedCamCFrame = nil

RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if not cam then return end
    
    if isBuyingEgg and lockedCamCFrame then
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = lockedCamCFrame
    elseif Library.Flags["Auto Buy Egg (Common)"] or Library.Flags["Auto Buy Egg (Rare)"] or Library.Flags["Auto Buy Egg (Epic)"] then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum and cam.CameraSubject ~= hum then
            cam.CameraSubject = hum
            cam.CameraType = Enum.CameraType.Custom
        end
    end
end)

task.spawn(function()
    local eggTypes = {
        {Flag = "Auto Buy Egg (Common)", Name = "CommonEgg", Price = 25000000, DisplayName = "Common Egg"},
        {Flag = "Auto Buy Egg (Rare)", Name = "RareEgg", Price = 25000000000, DisplayName = "Rare Egg"},
        {Flag = "Auto Buy Egg (Epic)", Name = "EpicEgg", Price = 10000000000000, DisplayName = "Epic Egg"}
    }

    local slotCFrames = {
        CFrame.new(-225.472153, 5.76001072, 25.4643955),
        CFrame.new(-225.423996, 5.77058411, 18.9826889),
        CFrame.new(-225.599045, 5.79407978, 12.6490135),
        CFrame.new(-225.555573, 5.75883579, 6.24953842)
    }

    while not isUnloaded do
        local boughtAny = false
        
        for _, egg in ipairs(eggTypes) do
            if Library.Flags[egg.Flag] == true and getPlayerCash() >= egg.Price then
                local foundEgg = workspace:FindFirstChild(egg.Name) or workspace:FindFirstChild(egg.Name, true)
                
                if foundEgg and foundEgg:IsA("Model") then
                    local eggPos = foundEgg:GetPivot().Position
                    local targetCFrame = nil
                    local minMag = math.huge
                    
                    for _, cframe in ipairs(slotCFrames) do
                        local mag = (Vector3.new(eggPos.X, 0, eggPos.Z) - Vector3.new(cframe.X, 0, cframe.Z)).Magnitude
                        if mag < 5 and mag < minMag then
                            minMag = mag
                            targetCFrame = cframe
                        end
                    end
                    
                    if targetCFrame then
                        local prompt = foundEgg:FindFirstChildWhichIsA("ProximityPrompt", true)
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        
                        if prompt and hrp then
                            lockedCamCFrame = workspace.CurrentCamera.CFrame
                            isBuyingEgg = true
                            
                            local oldCFrame = hrp.CFrame
                            local oldCash = getPlayerCash()
                            
                            hrp.CFrame = targetCFrame + Vector3.new(0, 3, 0) 
                            task.wait(0.2)
                            
                            if fireproximityprompt then
                                pcall(fireproximityprompt, prompt)
                            else
                                pcall(function()
                                    prompt:InputBegan(Enum.UserInputType.Keyboard)
                                    task.wait((prompt.HoldDuration or 0) + 0.1)
                                    prompt:InputEnded(Enum.UserInputType.Keyboard)
                                end)
                            end
                            
                            task.wait(0.5)
                            
                            hrp.CFrame = oldCFrame
                            isBuyingEgg = false
                            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
                            
                            if getPlayerCash() < oldCash then
                                createNotification("Egg Obtained", "Successfully purchased " .. egg.DisplayName)
                                boughtAny = true
                            end
                        end
                    end
                end
            end
        end
        
        if not boughtAny then
            task.wait(0.2)
        end
    end
end)

task.spawn(function()
    while not isUnloaded do
        local isDiscarding = Library.Flags["Auto Discard Seeds"]
        local specFilter = Library.Flags["Discard Specific Seeds"]
        local rarFilter = Library.Flags["Discard Rarity"]
        
        if isDiscarding then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChild("Humanoid")
                if hum then
                    local tools = {}
                    for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end
                    for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") then table.insert(tools, t) end end
                    
                    local discardedAny = false
                    for _, tool in ipairs(tools) do
                        local cleanName = tool.Name:gsub(" Seed", ""):gsub(" Shooter", "")
                        local baseName = cleanName:gsub("%s*%(x%d+%)", "")
                        baseName = baseName:match("^%s*(.-)%s*$") or baseName
                        
                        local qtyMatch = tool.Name:match("%(x(%d+)%)")
                        local qty = qtyMatch and tonumber(qtyMatch) or 1
                        
                        local rarity = nil
                        for _, sData in ipairs(SeedData) do
                            if sData.Name == baseName then rarity = sData.Rarity; break end
                        end
                        
                        if (specFilter and specFilter[baseName]) or (rarFilter and rarity and rarFilter[rarity]) then
                            if tool.Parent ~= char then
                                hum:EquipTool(tool)
                                task.wait(0.2)
                            end
                            local rsRemotes = ReplicatedStorage:FindFirstChild("Remotes")
                            if rsRemotes and rsRemotes:FindFirstChild("DiscardSeed") then
                                for i = 1, qty do
                                    rsRemotes.DiscardSeed:FireServer()
                                    task.wait(0.1)
                                end
                                createNotification("Seed Discarded", "Discarded " .. tostring(qty) .. "x " .. baseName)
                                discardedAny = true
                            end
                        end
                    end
                    if discardedAny then task.wait(1) end
                end
            end)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while not isUnloaded do
        local isRollingActive = Library.Flags["Auto Roll & Buy Targets"] == true
        local isUpcycling = Library.Flags["Auto Upcycle Worst Crop (Lv 30 Max)"] == true
        local selectedTargets = Library.Flags["Target Seeds List"]
        local waitForCash = Library.Flags["Wait for Cash to Buy Seed"] == true
        local hasSelection = false
        
        if selectedTargets then
            for _, isSelected in pairs(selectedTargets) do 
                if isSelected then hasSelection = true break end 
            end
        end

        if isRollingActive or isUpcycling then
            if not hasSelection and not isUpcycling then
                task.wait(2)
            elseif not cachedPlot then
                task.wait(2)
            else
                local seedRoller = cachedPlot:FindFirstChild("SeedRoller")
                local targetFoundOnStand = false
                local cash = getPlayerCash()
                
                local worstRank = math.huge
                local worstDirt = nil
                local worstName = ""
                
                if isUpcycling then
                    for _, plotFolder in ipairs(cachedPlot:GetDescendants()) do
                        if (plotFolder:IsA("Folder") or plotFolder:IsA("Model")) and plotFolder.Name == "FarmPlot" then
                            for _, child in ipairs(plotFolder:GetChildren()) do
                                local dirt = child:FindFirstChild("Dirt")
                                if dirt and dirt:GetAttribute("PlantName") then
                                    local pName = dirt:GetAttribute("PlantName")
                                    local pRank = GetPlantRank(pName)
                                    if pRank < worstRank and pName ~= "Garden Golem" then
                                        worstRank = pRank
                                        worstDirt = dirt
                                        worstName = pName
                                    end
                                end
                            end
                        end
                    end
                end

                if seedRoller then
                    pcall(function()
                        for standNum = 1, 6 do
                            local stand = seedRoller:FindFirstChild("Stand" .. standNum)
                            if stand then
                                local standPos = stand:GetPivot().Position
                                for _, obj in safeIpairs(workspace:GetChildren()) do
                                    if obj:IsA("Model") and obj.Name ~= LocalPlayer.Name and obj.Name ~= "AxiomHub_Core" then
                                        local objPos = obj:GetPivot().Position
                                        local hDist = math.sqrt((objPos.X - standPos.X)^2 + (objPos.Z - standPos.Z)^2)
                                        local vDist = math.abs(objPos.Y - standPos.Y)
                                        
                                        local hasPriceTag = false
                                        local price = nil
                                        for _, desc in safeIpairs(obj:GetDescendants()) do
                                            if desc:IsA("TextLabel") and desc.Text:find("%$") then
                                                hasPriceTag = true
                                                local match = desc.Text:match("%$([%d%.%a,]+)")
                                                if match then 
                                                    price = parsePriceString(match) 
                                                    break
                                                end
                                            end
                                        end
                                        
                                        if hasPriceTag and hDist <= 4.5 and vDist <= 15 then
                                            local baseName = obj.Name:gsub(" Seed", ""):gsub(" Shooter", "")
                                            
                                            local isVerifiedSeed = false
                                            local seedRank = 1
                                            for _, sData in ipairs(SeedData) do
                                                if sData.Name == baseName then
                                                    isVerifiedSeed = true
                                                    seedRank = sData.Rank
                                                    break
                                                end
                                            end
                                            
                                            if not isVerifiedSeed then continue end
                                            
                                            local wantsToBuy = false
                                            local isUpcycleBuy = false
                                            if isRollingActive and selectedTargets and selectedTargets[baseName] then
                                                wantsToBuy = true
                                            elseif isUpcycling and worstDirt and seedRank > worstRank then
                                                wantsToBuy = true
                                                isUpcycleBuy = true
                                            end
                                            
                                            if wantsToBuy then
                                                if not price or cash >= price then
                                                    targetFoundOnStand = true
                                                    local oldCash = getPlayerCash()
                                                    
                                                    BuySeedEvent:FireServer(standNum, true)
                                                    
                                                    task.wait(0.3)
                                                    if getPlayerCash() < oldCash then
                                                        Library.PurchasedSeeds[baseName] = (Library.PurchasedSeeds[baseName] or 0) + 1
                                                        UpdatePurchasedSeedsUI()
                                                        createNotification("Seed Purchased", "Acquired: " .. tostring(baseName))
                                                        
                                                        if isUpcycleBuy and worstDirt then
                                                            local rsRemotes = ReplicatedStorage:FindFirstChild("Remotes")
                                                            if rsRemotes and rsRemotes:FindFirstChild("RemovePlant") then
                                                                rsRemotes.RemovePlant:FireServer(worstDirt)
                                                                task.wait(0.3)
                                                                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                                                                if hum then EquipItemByName(baseName) end
                                                                task.wait(0.2)
                                                                if rsRemotes:FindFirstChild("PlantSeed") then
                                                                    rsRemotes.PlantSeed:FireServer(worstDirt)
                                                                    createNotification("Upcycled!", worstName .. " -> " .. baseName)
                                                                    Library.UpcycleUpgrades[worstDirt] = true
                                                                    table.insert(Library.ReplacedCrops, 1, {name = baseName, old = worstName, dirt = worstDirt})
                                                                end
                                                            end
                                                        end
                                                    end
                                                    break
                                                elseif waitForCash then
                                                    targetFoundOnStand = true 
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
                
                if not targetFoundOnStand then 
                    pcall(function() RollSeedsEvent:FireServer() end) 
                    task.wait(1.5) 
                else 
                    task.wait(0.5) 
                end
            end
        else
            task.wait(0.2)
        end
    end
end)

task.spawn(function()
    while not isUnloaded do
        if Library.Flags["Auto Buy ANY Transcendent Seed"] == true and cachedPlot then
            local seedRoller = cachedPlot:FindFirstChild("SeedRoller")
            pcall(function()
                if seedRoller then
                    for standNum = 1, 6 do
                        local stand = seedRoller:FindFirstChild("Stand" .. standNum)
                        if stand then
                            local standPos = stand:GetPivot().Position
                            for _, obj in safeIpairs(workspace:GetChildren()) do
                                if obj:IsA("Model") and obj.Name ~= LocalPlayer.Name and obj.Name ~= "AxiomHub_Core" then
                                    local objPos = obj:GetPivot().Position
                                    local hDist = math.sqrt((objPos.X - standPos.X)^2 + (objPos.Z - standPos.Z)^2)
                                    local vDist = math.abs(objPos.Y - standPos.Y)
                                    
                                    local hasPriceTag = false
                                    local price = nil
                                    for _, desc in safeIpairs(obj:GetDescendants()) do
                                        if desc:IsA("TextLabel") and desc.Text:find("%$") then
                                            hasPriceTag = true
                                            local match = desc.Text:match("%$([%d%.%a,]+)")
                                            if match then 
                                                price = parsePriceString(match) 
                                                break
                                            end
                                        end
                                    end
                                    
                                    if hasPriceTag and hDist <= 4.5 and vDist <= 15 and (not price or getPlayerCash() >= price) then
                                        local isTranscendent = false
                                        for _, desc in safeIpairs(obj:GetDescendants()) do
                                            if desc:IsA("TextLabel") and desc.Text:lower():find("transcendent") then
                                                isTranscendent = true; break
                                            end
                                        end
                                        
                                        local baseName = obj.Name:gsub(" Seed", ""):gsub(" Shooter", "")
                                        if not isTranscendent then
                                            for _, sData in ipairs(SeedData) do
                                                if sData.Name == baseName and sData.Rarity == "Transcendent" then
                                                    isTranscendent = true; break
                                                end
                                            end
                                        end
                                        
                                        if isTranscendent then
                                            local oldCash = getPlayerCash()
                                            
                                            BuySeedEvent:FireServer(standNum, true)
                                            
                                            task.wait(0.3)
                                            if getPlayerCash() < oldCash then
                                                Library.PurchasedSeeds[baseName] = (Library.PurchasedSeeds[baseName] or 0) + 1
                                                UpdatePurchasedSeedsUI()
                                                createNotification("Transcendent Secured!", "Acquired Rare Drop: " .. tostring(baseName))
                                            end
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

task.spawn(function()
    while not isUnloaded do
        local modeSpecific = Library.Flags["Auto Place (By Specific Seed)"]
        local modeRarity = Library.Flags["Auto Place (By Rarity)"]
        
        if (modeSpecific or modeRarity) and cachedPlot then
            pcall(function()
                local bestSeedName = nil
                local bestTool = nil
                local highestRank = 0
                
                local tools = {}
                for _, obj in ipairs(LocalPlayer.Backpack:GetChildren()) do
                    if obj:IsA("Tool") then table.insert(tools, obj) end
                end
                if LocalPlayer.Character then
                    for _, obj in ipairs(LocalPlayer.Character:GetChildren()) do
                        if obj:IsA("Tool") then table.insert(tools, obj) end
                    end
                end

                for _, tool in ipairs(tools) do
                    local tName = string.lower(tool.Name)
                    for _, data in ipairs(SeedData) do
                        local dName = string.lower(data.Name)
                        if string.find(tName, "^" .. dName) then
                            local isValid = false
                            if modeSpecific and Library.Flags["Specific Plant Targets"] and Library.Flags["Specific Plant Targets"][data.Name] then
                                isValid = true
                            elseif modeRarity and Library.Flags["Rarity Plant Targets"] and Library.Flags["Rarity Plant Targets"][data.Rarity] then
                                isValid = true
                            end
                            
                            if isValid and data.Rank > highestRank then
                                highestRank = data.Rank
                                bestTool = tool
                                bestSeedName = data.Name
                            end
                        end
                    end
                end

                if bestTool and bestSeedName then
                    local planted = false
                    for _, plotFolder in ipairs(cachedPlot:GetDescendants()) do
                        if (plotFolder:IsA("Folder") or plotFolder:IsA("Model")) and plotFolder.Name == "FarmPlot" then
                            for _, child in ipairs(plotFolder:GetChildren()) do
                                if child:GetAttribute("Unlocked") ~= false then
                                    local dirt = child:FindFirstChild("Dirt")
                                    if dirt and dirt:IsA("BasePart") and dirt:GetAttribute("PlantName") == nil then
                                        if bestTool.Parent ~= LocalPlayer.Character then
                                            LocalPlayer.Character.Humanoid:EquipTool(bestTool)
                                            task.wait(0.2)
                                        end
                                        PlantSeedEvent:FireServer(dirt)
                                        createNotification("Seed Planted", "Planted: " .. bestSeedName)
                                        planted = true
                                        task.wait(0.2)
                                        break
                                    end
                                end
                            end
                        end
                        if planted then break end
                    end
                end
            end)
            task.wait(1)
        else
            task.wait(0.2)
        end
    end
end)

task.spawn(function()
    while not isUnloaded do
        local modeAll = Library.Flags["Auto Upgrade All Plants"]
        local modeSpecific = Library.Flags["Auto Upgrade Specific Plants"]
        local activeFloors = Library.Flags["Upgrade Floors List"] or {}
        local upgDelay = Library.Flags["Upgrade Delay"]
        if upgDelay == nil then upgDelay = 0.5 end
        
        if (modeAll or modeSpecific or next(Library.UpcycleUpgrades)) and cachedPlot then
            pcall(function()
                local upgradeCandidates = {}

                for _, plotFolder in ipairs(cachedPlot:GetDescendants()) do
                    if (plotFolder:IsA("Folder") or plotFolder:IsA("Model")) and plotFolder.Name == "FarmPlot" then
                        local parentName = plotFolder.Parent and plotFolder.Parent.Name or ""
                        local floorNum = 1
                        local matchFloor = parentName:match("^Floor(%d+)$")
                        if matchFloor then
                            floorNum = tonumber(matchFloor)
                        end
                        
                        local floorName = "Floor " .. floorNum
                        local floorAllowed = true
                        local hasAnySelection = false
                        for _, v in pairs(activeFloors) do if v then hasAnySelection = true break end end
                        if hasAnySelection then
                            floorAllowed = activeFloors[floorName] == true
                        end
                        
                        for _, child in ipairs(plotFolder:GetChildren()) do
                            if child:IsA("Model") then
                                local dirt = child:FindFirstChild("Dirt")
                                if dirt then
                                    local pName = dirt:GetAttribute("PlantName")
                                    if not pName then
                                        for _, sData in ipairs(SeedData) do
                                            if dirt:FindFirstChild(sData.Name) or child:FindFirstChild(sData.Name) then
                                                pName = sData.Name
                                                break
                                            end
                                        end
                                    end
                                    
                                    local pLevel = dirt:GetAttribute("PlantLevel") or 1
                                    
                                    if pName then
                                        local isValid = false
                                        local isUpcycle = Library.UpcycleUpgrades[dirt] == true
                                        
                                        if isUpcycle then
                                            if pLevel < 30 then
                                                isValid = true
                                                pLevel = pLevel - 1000 
                                            else
                                                Library.UpcycleUpgrades[dirt] = nil
                                            end
                                        elseif floorAllowed then
                                            if modeAll then
                                                isValid = true
                                            elseif modeSpecific and Library.Flags["Specific Upgrade Targets"] and Library.Flags["Specific Upgrade Targets"][pName] then
                                                isValid = true
                                            end
                                        end
                                        
                                        if isValid then
                                            table.insert(upgradeCandidates, {
                                                dirt = dirt,
                                                name = pName,
                                                level = pLevel
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if #upgradeCandidates > 0 then
                    table.sort(upgradeCandidates, function(a, b)
                        return a.level < b.level
                    end)

                    for _, candidate in ipairs(upgradeCandidates) do
                        local price = 0
                        if SharedUtils and type(SharedUtils.CalculateSeedUpgradePrice) == "function" then
                            pcall(function()
                                price = SharedUtils.CalculateSeedUpgradePrice(candidate.name, candidate.level >= 0 and candidate.level or candidate.level + 1000)
                            end)
                        end
                        
                        if getPlayerCash() >= price then
                            local oldCash = getPlayerCash()
                            UpgradePlantEvent:InvokeServer(candidate.dirt)
                            task.wait(0.1)
                            
                            if getPlayerCash() < oldCash then
                                task.wait(upgDelay)
                                break 
                            end
                        end
                    end
                end
            end)
            task.wait(upgDelay > 0 and upgDelay or 0.1)
        else
            task.wait(0.2)
        end
    end
end)

-- ==============================================================================
-- [ DO NOT EDIT OR TOUCH THIS ] - END OF ENGINE PROTECTION SECTION
-- ==============================================================================

task.spawn(function()
    while not isUnloaded do
        if Library.Flags["Auto Buy Plot"] == true and cachedPlot then
            pcall(function()
                for _, plotFolder in ipairs(cachedPlot:GetDescendants()) do
                    if (plotFolder:IsA("Folder") or plotFolder:IsA("Model")) and plotFolder.Name == "FarmPlot" then
                        for _, child in ipairs(plotFolder:GetChildren()) do
                            if child:GetAttribute("Unlocked") == false and child:FindFirstChild("Dirt") then
                                UnlockPlotEvent:FireServer(child.Dirt)
                                createNotification("Plot Expanded", "Unlocked a new garden tile.")
                            end
                        end
                    end
                end
            end)
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

task.spawn(function()
    while not isUnloaded do
        if Library.Flags["Auto Kill Plant Enemy"] == true and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local originPos = LocalPlayer.Character.HumanoidRootPart.Position
                local plantRushFolder = workspace:FindFirstChild("InteractiveEvents") and workspace.InteractiveEvents:FindFirstChild("PlantRush")
                if plantRushFolder and plantRushFolder:FindFirstChild("Runtime") then
                    for _, plant in safeIpairs(plantRushFolder.Runtime:GetChildren()) do
                        local hitPart = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart", true)
                        if hitPart then
                            local targetPos = hitPart.Position
                            local shootDirection = (targetPos - originPos).Unit
                            for burst = 1, 5 do PlantRushShootEvent:FireServer(originPos, shootDirection, targetPos) end
                        end
                    end
                end
            end)
            task.wait(0.1)
        else
            task.wait(0.2)
        end
    end
end)

task.spawn(function()
    while not isUnloaded do
        if Library.Flags["Auto Pickup Loot Drops"] == true then
            pcall(function()
                for _, part in safeIpairs(workspace:GetChildren()) do
                    if part.Name:find("PlantRushLocalDrop_") then
                        local dropId = part.Name:gsub("PlantRushLocalDrop_", "")
                        if dropId ~= "" then 
                            DropClaimEvent:FireServer(dropId) 
                            createNotification("Loot Claimed", "Collected drop ID: " .. dropId)
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while not isUnloaded do
        local selectedGear = Library.Flags["Target Gear List"]
        local isGearActive = Library.Flags["Auto Buy Selected Gear"] == true
        
        if isGearActive and selectedGear then
            local cash = getPlayerCash()
            for _, gData in ipairs(GearData) do
                if selectedGear[gData.Name] and cash >= gData.Price then
                    task.spawn(function()
                        local oldCash = getPlayerCash()
                        pcall(function() GearTransactionEvent:InvokeServer(gData.Name) end)
                        task.wait(0.3)
                        if getPlayerCash() < oldCash then
                            createNotification("Gear Purchased", "Bought: " .. gData.Name)
                        end
                    end)
                end
            end
            task.wait(0.1) 
        else
            task.wait(0.2)
        end
    end
end)

task.spawn(function()
    while not isUnloaded do
        if Library.Flags["Auto Collect Honeycomb"] == true and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local qBeeFolder = workspace:FindFirstChild("InteractiveEvents") and workspace.InteractiveEvents:FindFirstChild("QueenBee")
                local honeycombsFolder = qBeeFolder and qBeeFolder:FindFirstChild("RuntimeHoneycombs")
                if honeycombsFolder then
                    for _, honeycomb in safeIpairs(honeycombsFolder:GetChildren()) do
                        local targetPart = honeycomb:IsA("BasePart") and honeycomb or honeycomb.PrimaryPart or honeycomb:FindFirstChildWhichIsA("BasePart", true)
                        local prompt = honeycomb:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if targetPart and prompt then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 1.5, 0)
                            task.wait(0.1)
                            safeFirePrompt(prompt)
                            task.wait(0.1)
                        end
                    end
                end
            end)
        end
        task.wait(0.3)
    end
end)

task.spawn(function()
    while not isUnloaded do
        if Library.Flags["Auto Insert Honey Token"] then
            local hasTokens = false
            for _, obj in safeIpairs(LocalPlayer.Backpack:GetChildren()) do
                if obj:IsA("Tool") and obj.Name:find("Honey") and obj.Name:find("Token") then hasTokens = true break end
            end
            if not hasTokens and LocalPlayer.Character then
                for _, obj in safeIpairs(LocalPlayer.Character:GetChildren()) do
                    if obj:IsA("Tool") and obj.Name:find("Honey") and obj.Name:find("Token") then hasTokens = true break end
                end
            end
            
            if hasTokens then
                pcall(function()
                    local prompt = workspace.InteractiveEvents.QueenBee.HoneyJarMachine["Honey Jar Machine"].InsertPrompt
                    if prompt then
                        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local oldCFrame = hrp.CFrame
                            hrp.CFrame = prompt.Parent.CFrame + Vector3.new(0, 3, 0)
                            task.wait(0.2)
                            if fireproximityprompt then
                                pcall(fireproximityprompt, prompt)
                            else
                                safeFirePrompt(prompt)
                            end
                            task.wait(0.2)
                            hrp.CFrame = oldCFrame
                        end
                    end
                end)
                task.wait(0.2)
            else
                Library.Flags["Auto Insert Honey Token"] = false
                createNotification("Task Complete", "Inserted all Honey Tokens.")
                task.wait(1)
            end
        else
            task.wait(0.5)
        end
    end
end)
