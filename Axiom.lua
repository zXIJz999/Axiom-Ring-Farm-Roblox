-- ==============================================================================
-- AXIOM UNIVERSAL LOADER
-- Fetches and executes specific game scripts from GitHub repository
-- ==============================================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local GithubRawUrl = "https://raw.githubusercontent.com/zXIJz999/Axiom-Ring-Farm-Roblox/main/Axiom-%s.lua"

local SupportedGames = {
    {Name = "Kick a Lucky Block", PlaceId = 89469502395769},
    {Name = "Build A Ring Farm", PlaceId = game.PlaceId}, -- Uses current PlaceId for Ring Farm (Update if you know the exact ID)
}

-- Destroy old loader if it exists
if CoreGui:FindFirstChild("AxiomUniversalLoader") then
    CoreGui.AxiomUniversalLoader:Destroy()
end

-- ==============================================================================
-- THEMES & UI CREATION
-- ==============================================================================
local Theme = {
    MainBg      = Color3.fromRGB(12, 12, 12),
    ElementBg   = Color3.fromRGB(24, 24, 26),
    ElementHov  = Color3.fromRGB(35, 35, 40),
    Accent      = Color3.fromRGB(255, 50, 50),
    Text        = Color3.fromRGB(255, 255, 255),
    TextDim     = Color3.fromRGB(160, 160, 170),
    Border      = Color3.fromRGB(45, 45, 50)
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AxiomUniversalLoader"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
MainFrame.BackgroundColor3 = Theme.MainBg
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Theme.Border
UIStroke.Thickness = 1
UIStroke.Parent = MainFrame

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 60)
Header.BackgroundColor3 = Theme.ElementBg
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

local HeaderFix = Instance.new("Frame") -- Covers bottom corners of header to attach to list
HeaderFix.Size = UDim2.new(1, 0, 0, 10)
HeaderFix.Position = UDim2.new(0, 0, 1, -10)
HeaderFix.BackgroundColor3 = Theme.ElementBg
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, 0, 0, 1)
HeaderLine.Position = UDim2.new(0, 0, 1, 0)
HeaderLine.BackgroundColor3 = Theme.Border
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "AXIOM UNIVERSAL"
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Theme.Accent
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -20, 1, 0)
SubTitle.Position = UDim2.new(0, 20, 0, 16)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Game Selection Hub"
SubTitle.Font = Enum.Font.GothamMedium
SubTitle.TextColor3 = Theme.TextDim
SubTitle.TextSize = 12
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = Header

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -20, 1, -80)
Content.Position = UDim2.new(0, 10, 0, 70)
Content.BackgroundTransparency = 1
Content.ScrollBarThickness = 2
Content.ScrollBarImageColor3 = Theme.Border
Content.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = Content

-- Status Label for Loading
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 1, -25)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Awaiting selection..."
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextColor3 = Theme.TextDim
StatusLabel.TextSize = 12
StatusLabel.Parent = MainFrame

-- ==============================================================================
-- LOGIC & EXECUTION
-- ==============================================================================
local function ExecuteScript(placeId)
    StatusLabel.TextColor3 = Theme.Text
    StatusLabel.Text = "Fetching Axiom-" .. tostring(placeId) .. ".lua..."
    
    task.spawn(function()
        local formattedUrl = string.format(GithubRawUrl, tostring(placeId))
        
        local success, scriptContent = pcall(function()
            return game:HttpGet(formattedUrl)
        end)

        if success and scriptContent and not string.find(scriptContent, "404: Not Found") then
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            StatusLabel.Text = "Injection Successful!"
            task.wait(0.5)
            ScreenGui:Destroy() -- Destroy loader
            
            -- Run the fetched script
            local loadFunc, loadErr = loadstring(scriptContent)
            if loadFunc then
                loadFunc()
            else
                warn("Axiom Hub Load Error: ", loadErr)
            end
        else
            StatusLabel.TextColor3 = Theme.Accent
            StatusLabel.Text = "Failed: Script not found on GitHub!"
            task.wait(2)
            StatusLabel.TextColor3 = Theme.TextDim
            StatusLabel.Text = "Awaiting selection..."
        end
    end)
end

local function CreateButton(text, isAuto)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -10, 0, 45)
    Btn.BackgroundColor3 = Theme.ElementBg
    Btn.Text = text
    Btn.Font = Enum.Font.GothamBold
    Btn.TextColor3 = isAuto and Theme.Accent or Theme.Text
    Btn.TextSize = 14
    Btn.AutoButtonColor = false
    Btn.Parent = Content

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Btn

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Theme.Border
    Stroke.Thickness = 1
    Stroke.Parent = Btn

    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementHov}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementBg}):Play()
    end)
    
    return Btn
end

-- 1. Auto-Detect Button (Uses the PlaceId of whatever game you are currently in)
local AutoDetectBtn = CreateButton("⚡ Auto-Detect Current Game", true)
AutoDetectBtn.MouseButton1Click:Connect(function()
    ExecuteScript(game.PlaceId)
end)

-- Separator
local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(1, -10, 0, 1)
Sep.BackgroundColor3 = Theme.Border
Sep.BorderSizePixel = 0
Sep.Parent = Content

-- 2. Known Supported Games List
for _, gameData in ipairs(SupportedGames) do
    local Btn = CreateButton(gameData.Name .. " (" .. tostring(gameData.PlaceId) .. ")", false)
    Btn.MouseButton1Click:Connect(function()
        ExecuteScript(gameData.PlaceId)
    end)
end

Content.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
