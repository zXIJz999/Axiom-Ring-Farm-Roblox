-- ==============================================================================
-- AXIOM HUB UI FRAMEWORK - FINAL BUILD (Mobile Scaling & Auto-Config Patch)
-- Features: Auto-Save Configs, Responsive Mobile UI, Seed Planner, Anti-Spam
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

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local UI_PARENT = RunService:IsStudio() and LocalPlayer:WaitForChild("PlayerGui") or CoreGui

-- ==============================================================================
-- CONFIGURATION SYSTEM (Auto Save/Load)
-- ==============================================================================
local ConfigFileName = "AxiomHub_SavedConfig.json"

local Library = {
    ActiveTab = nil,
    Windows = {},
    Flags = {
        ["Screen Notifications"] = true
    }, 
    Settings = { ToggleKey = Enum.KeyCode.RightShift, Watermark = true },
    SessionStart = os.time()
}

local function LoadConfig()
    if isfile and isfile(ConfigFileName) and readfile then
        pcall(function()
            local savedData = HttpService:JSONDecode(readfile(ConfigFileName))
            if type(savedData) == "table" then
                for k, v in pairs(savedData) do
                    Library.Flags[k] = v
                end
            end
        end)
    end
end

local function SaveConfig()
    if writefile then
        pcall(function()
            writefile(ConfigFileName, HttpService:JSONEncode(Library.Flags))
        end)
    end
end

-- Load user settings before building UI
LoadConfig()

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

local GearTransactionEvent = Remotes:WaitForChild("Gear"):WaitForChild("Transaction")
local EggTransactionEvent = Remotes:FindFirstChild("Egg") and Remotes.Egg:FindFirstChild("Transaction") or Remotes:FindFirstChild("BuyEgg")

local AlertEvent = Remotes:WaitForChild("Alert")

local PlantRushFolder = Remotes:WaitForChild("PlantRush")
local PlantRushShootEvent = PlantRushFolder:WaitForChild("Shoot")
local DropClaimEvent = PlantRushFolder:WaitForChild("DropClaim")

local cachedPlot = nil

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
-- MASTER DATABASES & RARITY COLORS
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
    {Name = "Garden Devourer", Rarity = "Transcendent", Rank = 68}, {Name = "Papaya", Rarity = "Transcendent", Rank = 69}, {Name = "Durian", Rarity = "Transcendent", Rank = 70}, {Name = "Ghost Pepper", Rarity = "Transcendent", Rank = 71}, {Name = "Ember Fruit", Rarity = "Transcendent", Rank = 72}, {Name = "Queens Blossom", Rarity = "Transcendent", Rank = 73}, {Name = "Heart of Corruption", Rarity = "Transcendent", Rank = 74}, {Name = "Soulbound Orchid", Rarity = "Transcendent", Rank = 75}, {Name = "Garden Golem", Rarity = "Transcendent", Rank = 76}
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
            task.wait(0.05)
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

-- ==============================================================================
-- MAIN WINDOW GENERATION
-- ==============================================================================
function Library:CreateWindow(config)
    local TitleText = config.Title or "AXIOM"
    local SubText = config.Subtitle or "HUB V1.0"

    -- Using Relative Scaling for true mobile support (85% of screen size)
    local MainFrame = Create("Frame", { Name = "MainFrame", Parent = ScreenGui, Size = UDim2.new(0.85, 0, 0.85, 0), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.MainBg, BorderSizePixel = 0, ClipsDescendants = true })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = MainFrame })
    Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = MainFrame })

    local SizeConstraint = Create("UISizeConstraint", { Parent = MainFrame, MinSize = Vector2.new(400, 250), MaxSize = Vector2.new(850, 600) })

    local DragHeader = Create("Frame", { Parent = MainFrame, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, ZIndex = 100 })
    MakeDraggable(DragHeader, MainFrame)

    local MinimizeBtn = Create("TextButton", { Parent = DragHeader, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(1, -45, 0, 5), BackgroundTransparency = 1, Text = "—", Font = Theme.FontBold, TextColor3 = Theme.TextDim, TextSize = 18, ZIndex = 101 })

    local Sidebar = Create("Frame", { Parent = MainFrame, Size = UDim2.new(0, 180, 1, 0), BackgroundColor3 = Theme.SidebarBg, BorderSizePixel = 0 })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Sidebar }) 
    Create("Frame", { Parent = Sidebar, Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BackgroundColor3 = Theme.SidebarBg, BorderSizePixel = 0 })
    Create("Frame", { Parent = Sidebar, Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = Theme.Border, BorderSizePixel = 0 })

    local LogoText = Create("TextLabel", { Parent = Sidebar, Size = UDim2.new(1, -40, 0, 30), Position = UDim2.new(0, 15, 0, 25), BackgroundTransparency = 1, Text = TitleText, Font = Theme.FontBold, TextColor3 = Theme.Accent, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left })
    local SubLogoText = Create("TextLabel", { Parent = Sidebar, Size = UDim2.new(1, -40, 0, 15), Position = UDim2.new(0, 15, 0, 55), BackgroundTransparency = 1, Text = SubText, Font = Theme.Font, TextColor3 = Theme.TextDim, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })

    local TabContainer = Create("ScrollingFrame", { Parent = Sidebar, Size = UDim2.new(1, 0, 1, -110), Position = UDim2.new(0, 0, 0, 110), BackgroundTransparency = 1, ScrollBarThickness = 0 })
    Create("UIListLayout", { Parent = TabContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })

    local ContentArea = Create("Frame", { Parent = MainFrame, Size = UDim2.new(1, -180, 1, 0), Position = UDim2.new(0, 180, 0, 0), BackgroundTransparency = 1 })

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

    local FloatingToggle = Create("ImageButton", { Parent = ScreenGui, Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0.5, -25, 0, -60), BackgroundColor3 = Theme.MainBg, Visible = false, ZIndex = 100 })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = FloatingToggle })
    Create("UIStroke", { Color = Theme.Accent, Thickness = 2, Parent = FloatingToggle })
    local FloatText = Create("TextLabel", { Parent = FloatingToggle, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "A", Font = Theme.FontBold, TextColor3 = Theme.Accent, TextSize = 24 })
    
    local function ShowFloatingToggle()
        FloatingToggle.Visible = true
        Tween(FloatingToggle, {Position = UDim2.new(0.5, -25, 0, 20)}, 0.5, Enum.EasingStyle.Back)
    end
    
    local function HideFloatingToggle()
        local t = Tween(FloatingToggle, {Position = UDim2.new(0.5, -25, 0, -60)}, 0.5, Enum.EasingStyle.Back)
        t.Completed:Connect(function() FloatingToggle.Visible = false end)
    end

    MinimizeBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        ShowFloatingToggle()
    end)

    FloatingToggle.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        HideFloatingToggle()
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Library.Settings.ToggleKey then 
            MainFrame.Visible = not MainFrame.Visible 
            if MainFrame.Visible then HideFloatingToggle() else ShowFloatingToggle() end
        end
    end)

    local WindowAPI = {}
    local FirstTab = true

    function WindowAPI:CreateTab(TabName)
        local TabBtn = Create("TextButton", { Parent = TabContainer, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "", AutoButtonColor = false })
        local TabIndicator = Create("Frame", { Parent = TabBtn, Size = UDim2.new(0, 4, 0, 20), Position = UDim2.new(0, 0, 0.5, -10), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1 })
        Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = TabIndicator })
        local TabLabel = Create("TextLabel", { Parent = TabBtn, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 25, 0, 0), BackgroundTransparency = 1, Text = TabName, Font = Theme.Font, TextColor3 = Theme.TextDim, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })

        local Page = Create("ScrollingFrame", { Parent = ContentArea, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.Border, CanvasSize = UDim2.new(0, 0, 0, 0), Visible = false })
        Create("UIPadding", { Parent = Page, PaddingTop = UDim.new(0, 25), PaddingBottom = UDim.new(0, 25), PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 10) })
        
        local LeftCol = Create("Frame", { Parent = Page, Size = UDim2.new(0.5, -8, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 })
        local RightCol = Create("Frame", { Parent = Page, Size = UDim2.new(0.5, -8, 1, 0), Position = UDim2.new(0.5, 8, 0, 0), BackgroundTransparency = 1 })
        
        local LeftList = Create("UIListLayout", { Parent = LeftCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12), VerticalAlignment = Enum.VerticalAlignment.Top })
        local RightList = Create("UIListLayout", { Parent = RightCol, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 12), VerticalAlignment = Enum.VerticalAlignment.Top })

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

            local SectionFrame = Create("Frame", { Parent = targetCol, BackgroundColor3 = Theme.SectionBg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, currentHeight) })
            Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = SectionFrame })
            Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = SectionFrame })

            local SectionHeader = Create("Frame", { Parent = SectionFrame, Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1 })
            Create("TextLabel", { Parent = SectionHeader, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = SectionName, Font = Theme.FontBold, TextColor3 = Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
            Create("Frame", { Parent = SectionFrame, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0,0,0,35), BackgroundColor3 = Theme.Border, BorderSizePixel = 0 })

            local SectionContent = Create("Frame", { Parent = SectionFrame, Size = UDim2.new(1, 0, 1, -36), Position = UDim2.new(0, 0, 0, 36), BackgroundTransparency = 1 })
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
                
                local ProfFrame = Create("Frame", { Parent = SectionContent, Size = UDim2.new(1, 0, 0, ProfHeight), BackgroundTransparency = 1 })
                local AvatarImg = Create("ImageLabel", { Parent = ProfFrame, Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 15, 0, 5), BackgroundColor3 = Theme.ElementBg, Image = "rbxthumb://type=AvatarHeadShot&id="..tostring(LocalPlayer.UserId).."&w=150&h=150" })
                Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = AvatarImg })
                Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = AvatarImg })
                
                Create("TextLabel", { Parent = ProfFrame, Size = UDim2.new(1, -85, 0, 20), Position = UDim2.new(0, 75, 0, 10), BackgroundTransparency = 1, Text = LocalPlayer.DisplayName, Font = Theme.FontBold, TextColor3 = Theme.Text, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left })
                Create("TextLabel", { Parent = ProfFrame, Size = UDim2.new(1, -85, 0, 20), Position = UDim2.new(0, 75, 0, 30), BackgroundTransparency = 1, Text = "@" .. LocalPlayer.Name .. "  |  ID: " .. tostring(LocalPlayer.UserId), Font = Theme.Font, TextColor3 = Theme.TextDim, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
            end

            function SectionAPI:CreateLabel(text)
                local LblHeight = 20
                AddElementHeight(LblHeight)
                local LblFrame = Create("Frame", { Parent = SectionContent, Size = UDim2.new(1, 0, 0, LblHeight), BackgroundTransparency = 1 })
                local TextLabel = Create("TextLabel", { Parent = LblFrame, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = text, Font = Theme.Font, TextColor3 = Theme.TextDim, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
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

                local TogFrame = Create("Frame", { Parent = SectionContent, Size = UDim2.new(1, 0, 0, TogHeight), BackgroundTransparency = 1 })
                local Title = Create("TextLabel", { Parent = TogFrame, Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Text = Name, Font = Theme.Font, TextColor3 = State and Theme.Text or Theme.TextDim, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })

                local SwitchBtn = Create("TextButton", { Parent = TogFrame, Size = UDim2.new(0, 44, 0, 22), Position = UDim2.new(1, -59, 0.5, -11), BackgroundColor3 = State and Theme.Accent or Theme.ElementBg, Text = "", AutoButtonColor = false })
                Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchBtn })
                local SwitchStroke = Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = SwitchBtn, Transparency = State and 1 or 0 })

                local SwitchKnob = Create("Frame", { Parent = SwitchBtn, Size = UDim2.new(0, 16, 0, 16), Position = State and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255) })
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

            function SectionAPI:CreateButton(opts)
                local Name = opts.Name or "Button"
                local Callback = opts.Callback or function() end
                local BtnHeight = 45
                AddElementHeight(BtnHeight)

                local BtnFrame = Create("Frame", { Parent = SectionContent, Size = UDim2.new(1, 0, 0, BtnHeight), BackgroundTransparency = 1 })
                local Button = Create("TextButton", { Parent = BtnFrame, Size = UDim2.new(1, -24, 0, 35), Position = UDim2.new(0, 12, 0, 5), BackgroundColor3 = Theme.ElementBg, Text = Name, Font = Theme.FontBold, TextColor3 = Theme.Text, TextSize = 13, AutoButtonColor = false })
                Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Button })
                
                Button.MouseButton1Click:Connect(Callback)
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

                local DropContainer = Create("Frame", { Parent = SectionContent, Size = UDim2.new(1, 0, 0, DropBaseHeight), BackgroundTransparency = 1, ClipsDescendants = true })
                
                local DropBtn = Create("TextButton", { Parent = DropContainer, Size = UDim2.new(1, -24, 0, 32), Position = UDim2.new(0, 12, 0, 4), BackgroundColor3 = Theme.ElementBg, Text = "", AutoButtonColor = false })
                Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropBtn })
                Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = DropBtn })

                local SelectedText = Create("TextLabel", { Parent = DropBtn, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = Name, Font = Theme.FontBold, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
                local Icon = Create("TextLabel", { Parent = DropBtn, Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -30, 0, 0), BackgroundTransparency = 1, Text = "▼", Font = Theme.Font, TextColor3 = Theme.TextDim, TextSize = 11 })

                local OptionsYOffset = 40
                local ExpandAmount = 200
                local SearchBox = nil

                if isSearchable then
                    OptionsYOffset = 75
                    ExpandAmount = 235
                    SearchBox = Create("TextBox", { Parent = DropContainer, Size = UDim2.new(1, -24, 0, 30), Position = UDim2.new(0, 12, 0, 40), BackgroundColor3 = Theme.MainBg, Text = "", PlaceholderText = "Search...", TextColor3 = Theme.Text, Font = Theme.Font, TextSize = 13 })
                    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SearchBox })
                    Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = SearchBox })
                end

                local OptionsFrame = Create("ScrollingFrame", { Parent = DropContainer, Size = UDim2.new(1, -24, 0, 0), Position = UDim2.new(0, 12, 0, OptionsYOffset), BackgroundColor3 = Theme.ElementBg, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, #ItemList * 35) })
                Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = OptionsFrame })
                Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = OptionsFrame })
                Create("UIListLayout", { Parent = OptionsFrame })

                local ItemButtons = {}

                for _, sData in ipairs(ItemList) do
                    local btn = Create("TextButton", { Parent = OptionsFrame, Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1, Text = "", AutoButtonColor = false })
                    ItemButtons[sData.Name] = btn
                    
                    local isSelected = Library.Flags[Flag][sData.Name] or false
                    
                    local checkbox = Create("Frame", { Parent = btn, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 10, 0.5, -8), BackgroundColor3 = Theme.MainBg })
                    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = checkbox })
                    Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = checkbox })
                    local checkFill = Create("Frame", { Parent = checkbox, Size = UDim2.new(1, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2), BackgroundColor3 = Theme.Accent, BackgroundTransparency = isSelected and 0 or 1 })
                    Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = checkFill })

                    local nameLabel = Create("TextLabel", { Parent = btn, Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 35, 0, 0), BackgroundTransparency = 1, Text = sData.Name, Font = Theme.FontBold, TextColor3 = Color3.fromRGB(255, 255, 255), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left })
                    
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

                if SearchBox then
                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        local q = string.lower(SearchBox.Text)
                        for itemName, btn in pairs(ItemButtons) do
                            if q == "" or string.find(string.lower(itemName), q) then
                                btn.Visible = true
                            else
                                btn.Visible = false
                            end
                        end
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
            end
            
            return SectionAPI
        end
        return TabAPI
    end
    
    return WindowAPI
end

-- ==============================================================================
-- MENU INITIALIZATION
-- ==============================================================================
local Window = Library:CreateWindow({ Title = "AXIOM", Subtitle = "HUB V1.0" })

local MainTab    = Window:CreateTab("Main Auto")
local CombatTab  = Window:CreateTab("Combat & Loot")
local ShopTab    = Window:CreateTab("Shop & Purchases")
local SeedsTab   = Window:CreateTab("Seeds & Rolls")
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

local UpgradeSection = MainTab:CreateSection("Auto Upgrade")
UpgradeSection:CreateToggle({ Name = "Auto Upgrade Plant" }) 

local EnvSection = MainTab:CreateSection("Environment")
EnvSection:CreateToggle({ Name = "Auto Use Fertiliser" }) 
EnvSection:CreateToggle({ Name = "Auto Use Spray" }) 
EnvSection:CreateToggle({ Name = "Auto Use Compost" }) 

local TokenSection = MainTab:CreateSection("Tokens")
TokenSection:CreateToggle({ Name = "Auto Collect Honeycomb" })
TokenSection:CreateToggle({ Name = "Auto Insert Honey Token" }) 

-- ====== COMBAT & LOOT TAB ======
local DefSection = CombatTab:CreateSection("Combat")
DefSection:CreateToggle({ Name = "Auto Kill Plant Enemy" })
DefSection:CreateToggle({ Name = "Auto Kill Boss" })

local LootSection = CombatTab:CreateSection("Looting")
LootSection:CreateToggle({ Name = "Auto Pickup Loot Drops" })

-- ====== SHOP & PURCHASES TAB ======
local AutoBuySec = ShopTab:CreateSection("Purchases")
AutoBuySec:CreateToggle({ Name = "Auto Buy Plot" }) 
AutoBuySec:CreateToggle({ Name = "Auto Buy Egg (Epic)" }) 

local GearShopSec = ShopTab:CreateSection("Gear Automation")
GearShopSec:CreateMultiSelect({ Name = "Select Target Gear", Flag = "Target Gear List", Items = GearData, Searchable = true })
GearShopSec:CreateToggle({ Name = "Auto Buy Selected Gear" })

-- ====== SEEDS & ROLLS TAB ======
local SeedSection = SeedsTab:CreateSection("Seed Manager")
SeedSection:CreateMultiSelect({ Name = "Select Target Seeds to Roll", Flag = "Target Seeds List", Items = SeedData, Searchable = true })
SeedSection:CreateToggle({ Name = "Auto Roll & Buy Targets" })
SeedSection:CreateToggle({ Name = "Auto Buy ANY Transcendent Seed" })

-- ====== INFO TAB & LIVE DATA ======
local UserSec = InfoTab:CreateSection("Player Profile")
UserSec:CreateProfile()
local PlayTimeLbl = UserSec:CreateLabel("Session Time: 00:00:00")

local GameSec = InfoTab:CreateSection("Live Game Data")
local CashLbl = GameSec:CreateLabel("Cash: Scanning...")
local CropsLbl = GameSec:CreateLabel("Planted Crops: Scanning...")

-- ====== SETTINGS TAB ======
local AlertSection = SettingsTab:CreateSection("Logs & Alerts")
AlertSection:CreateToggle({ Name = "Screen Notifications", Default = true })

local PerfSection = SettingsTab:CreateSection("Performance")
PerfSection:CreateToggle({ 
    Name = "Potato Graphics", 
    Callback = function(state)
        if state then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic
                elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1 end
            end
            game.Lighting.GlobalShadows = false
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
        end)
        
        pcall(function()
            if cachedPlot then
                local plantCount = 0
                for _, plot in ipairs(cachedPlot:GetDescendants()) do
                    if plot:IsA("Model") and plot:FindFirstChild("Plant") then plantCount = plantCount + 1 end
                end
                CropsLbl.Text = "Planted Crops: " .. tostring(plantCount)
            end
        end)
        task.wait(1)
    end
end)

task.spawn(function()
    while not isUnloaded do
        if Library.Flags["Auto Sell All Crops"] == true then
            pcall(function() SellCratesEvent:FireServer() end)
            task.wait(0.5)
        else
            task.wait(0.2)
        end
    end
end)

-- ==============================================================================
-- [ DO NOT EDIT OR TOUCH THIS ] - RUNTIME AUTO SEED AND ENGINE BACKGROUND LOOPS
-- ==============================================================================
task.spawn(function()
    while not isUnloaded do
        local isRollingActive = Library.Flags["Auto Roll & Buy Targets"] == true
        local selectedTargets = Library.Flags["Target Seeds List"]
        local hasSelection = false
        
        if selectedTargets then
            for _, isSelected in pairs(selectedTargets) do 
                if isSelected then hasSelection = true break end 
            end
        end

        if isRollingActive then
            if not hasSelection then
                task.wait(2)
            elseif not cachedPlot then
                task.wait(2)
            else
                local seedRoller = cachedPlot:FindFirstChild("SeedRoller")
                local targetFoundOnStand = false
                local cash = getPlayerCash()

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
                                        
                                        if hDist <= 4.5 and vDist <= 15 and selectedTargets[obj.Name] then
                                            local price = 0
                                            local foundPrice = false
                                            for _, desc in safeIpairs(obj:GetDescendants()) do
                                                if desc:IsA("TextLabel") and desc.Text:find("%$") then
                                                    local match = desc.Text:match("%$([%d%.%a,]+)")
                                                    if match then 
                                                        price = parsePriceString(match) 
                                                        foundPrice = true
                                                    end
                                                end
                                            end
                                            
                                            if not foundPrice or cash >= price then
                                                targetFoundOnStand = true
                                                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                                                if prompt then
                                                    safeFirePrompt(prompt)
                                                else
                                                    BuySeedEvent:FireServer(standNum, true)
                                                end
                                                createNotification("Seed Purchased", "Acquired: " .. tostring(obj.Name))
                                                task.wait(0.2)
                                                break
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
                                    
                                    if hDist <= 4.5 and vDist <= 15 then
                                        local isTranscendent = false
                                        for _, desc in safeIpairs(obj:GetDescendants()) do
                                            if desc:IsA("TextLabel") and desc.Text:lower():find("transcendent") then
                                                isTranscendent = true; break
                                            end
                                        end
                                        if not isTranscendent then
                                            for _, sData in ipairs(SeedData) do
                                                if sData.Name == obj.Name and sData.Rarity == "Transcendent" then
                                                    isTranscendent = true; break
                                                end
                                            end
                                        end
                                        if isTranscendent then
                                            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                                            if prompt then safeFirePrompt(prompt)
                                            else BuySeedEvent:FireServer(standNum, true) end
                                            createNotification("Transcendent Secured!", "Acquired Rare Drop: " .. tostring(obj.Name))
                                            task.wait(0.2)
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
                    local baseName = tool.Name:gsub(" Seed", ""):gsub(" Shooter", "")
                    for _, data in ipairs(SeedData) do
                        if data.Name == baseName then
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
                    for _, child in ipairs(cachedPlot:GetDescendants()) do
                        if child:IsA("Model") and child.Name:match("^Plot%d+$") then
                            if child:GetAttribute("Unlocked") ~= false then
                                local dirt = child:FindFirstChild("Dirt")
                                if dirt and dirt:GetAttribute("PlantName") == nil then
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
                end
            end)
            task.wait(1)
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
                for _, child in ipairs(cachedPlot:GetDescendants()) do
                    if child:IsA("Model") and child.Name:match("^Plot%d+$") then
                        if child:GetAttribute("Unlocked") == false and child:FindFirstChild("Dirt") then
                            UnlockPlotEvent:FireServer(child.Dirt)
                            createNotification("Plot Expanded", "Unlocked a new garden tile.")
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
        if Library.Flags["Auto Upgrade Plant"] == true and cachedPlot then
            pcall(function()
                for _, child in ipairs(cachedPlot:GetDescendants()) do
                    if child:IsA("Model") and child.Name:match("^Plot%d+$") then
                        local dirt = child:FindFirstChild("Dirt")
                        if dirt and dirt:GetAttribute("PlantName") then
                            UpgradePlantEvent:InvokeServer(dirt)
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
                        local success = pcall(function() GearTransactionEvent:InvokeServer(gData.Name) end)
                        if success then
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
        if Library.Flags["Auto Buy Egg (Epic)"] == true then
            task.spawn(function()
                local success = pcall(function()
                    if EggTransactionEvent then EggTransactionEvent:InvokeServer("Epic Egg") end
                end)
                if success then
                    createNotification("Egg Obtained", "Successfully purchased Epic Egg")
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
        if Library.Flags["Auto Collect Honeycomb"] == true then
            pcall(function()
                for _, obj in ipairs(workspace:GetChildren()) do
                    if obj.Name == "Honeycomb" or obj.Name == "HoneyToken" then
                        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then 
                            safeFirePrompt(prompt) 
                            createNotification("Honey Collected", "Acquired Token drop.")
                        end
                    end
                end
            end)
        end
        task.wait(0.5)
    end
end)
