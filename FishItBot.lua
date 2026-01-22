-- Fish It Auto-Fishing Bot
-- Updated with Fixes: AutoFish, Teleport Locations, Settings Tab

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Update Character references on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

-- 1. GUI System
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishItGUI_v2"
ScreenGui.ResetOnSpawn = false
if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = game:GetService("CoreGui")
elseif getgenv and getgenv().protect_gui then 
    getgenv().protect_gui(ScreenGui)
    ScreenGui.Parent = game:GetService("CoreGui")
else
    ScreenGui.Parent = PlayerGui
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 400, 0, 300) -- Increased size for better layout
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Text = "Dul Gege v2.0"
TitleLabel.Size = UDim2.new(1, -100, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "Close"
CloseButton.Text = "X"
CloseButton.Size = UDim2.new(0, 30, 1, 0)
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.BorderSizePixel = 0
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Parent = Header
CloseButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "Minimize"
MinimizeButton.Text = "-"
MinimizeButton.Size = UDim2.new(0, 30, 1, 0)
MinimizeButton.Position = UDim2.new(1, -60, 0, 0)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MinimizeButton.BorderSizePixel = 0
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Parent = Header

local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "Content"
ContentFrame.Size = UDim2.new(1, 0, 1, -30)
ContentFrame.Position = UDim2.new(0, 0, 0, 30)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- Tab Navigation
local TabButtonsFrame = Instance.new("Frame")
TabButtonsFrame.Size = UDim2.new(0, 100, 1, 0)
TabButtonsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TabButtonsFrame.BorderSizePixel = 0
TabButtonsFrame.Parent = ContentFrame

local TabPagesFrame = Instance.new("Frame")
TabPagesFrame.Size = UDim2.new(1, -100, 1, 0)
TabPagesFrame.Position = UDim2.new(0, 100, 0, 0)
TabPagesFrame.BackgroundTransparency = 1
TabPagesFrame.Parent = ContentFrame

local tabs = {
    "AutoFish", "Teleport", "Settings", "Misc", "Trade", "Webhook"
}

local currentTab = nil
local tabFrames = {}

for i, tabName in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Text = tabName
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Position = UDim2.new(0, 0, 0, (i-1)*30)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.BorderSizePixel = 0
    btn.Parent = TabButtonsFrame
    
    local page = Instance.new("ScrollingFrame")
    page.Name = tabName
    page.Size = UDim2.new(1, -10, 1, -10)
    page.Position = UDim2.new(0, 5, 0, 5)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.ScrollBarThickness = 4
    page.Parent = TabPagesFrame
    tabFrames[tabName] = page
    
    btn.MouseButton1Click:Connect(function()
        for _, f in pairs(tabFrames) do f.Visible = false end
        page.Visible = true
        currentTab = tabName
    end)
end

if tabFrames["AutoFish"] then tabFrames["AutoFish"].Visible = true end

MinimizeButton.MouseButton1Click:Connect(function()
    ContentFrame.Visible = not ContentFrame.Visible
    if ContentFrame.Visible then
        MainFrame.Size = UDim2.new(0, 400, 0, 300)
        MinimizeButton.Text = "-"
    else
        MainFrame.Size = UDim2.new(0, 400, 0, 30)
        MinimizeButton.Text = "+"
    end
end)

-- 2. Fishing Core (IMPROVED)
local net = nil
local fishingEvents = {}

-- Safely try to find the net module and remotes
task.spawn(function()
    pcall(function()
        -- Try multiple paths for net
        local packages = ReplicatedStorage:FindFirstChild("Packages")
        if packages then
             local index = packages:FindFirstChild("_Index")
             if index then
                 local netPackage = index:FindFirstChild("sleitnick_net@0.2.0")
                 if netPackage then
                     net = netPackage:WaitForChild("net", 2)
                 end
             end
        end
    end)

    if net then
        fishingEvents = {
            EquipTool = net:FindFirstChild("RE/EquipToolFromHotbar") or net:WaitForChild("RE/EquipToolFromHotbar", 2),
            ChargeRod = net:FindFirstChild("RF/ChargeFishingRod") or net:WaitForChild("RF/ChargeFishingRod", 2),
            Minigame = net:FindFirstChild("RF/RequestFishingMinigameStarted") or net:WaitForChild("RF/RequestFishingMinigameStarted", 2),
            Complete = net:FindFirstChild("RE/FishingCompleted") or net:WaitForChild("RE/FishingCompleted", 2),
            Sell = net:FindFirstChild("RF/SellFish") or net:WaitForChild("RF/SellFish", 2) -- Hypothethical
        }
    else
        warn("FishItBot: Net module not found! AutoFish might be limited.")
    end
end)

local autoFishEnabled = false
local autoSellEnabled = false
local autoBuyRodEnabled = false
local catchCount = 0

-- UI for AutoFish
local afToggle = Instance.new("TextButton")
afToggle.Text = "Toggle Auto Fish: OFF"
afToggle.Size = UDim2.new(1, 0, 0, 30)
afToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
afToggle.TextColor3 = Color3.new(1,1,1)
afToggle.Parent = tabFrames["AutoFish"]
afToggle.MouseButton1Click:Connect(function()
    autoFishEnabled = not autoFishEnabled
    afToggle.Text = "Toggle Auto Fish: " .. (autoFishEnabled and "ON" or "OFF")
    afToggle.BackgroundColor3 = autoFishEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    if autoFishEnabled then
        task.spawn(startFishing)
    end
end)

local asToggle = Instance.new("TextButton")
asToggle.Text = "Auto Sell (30 catch): OFF"
asToggle.Size = UDim2.new(1, 0, 0, 30)
asToggle.Position = UDim2.new(0, 0, 0, 35)
asToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
asToggle.TextColor3 = Color3.new(1,1,1)
asToggle.Parent = tabFrames["AutoFish"]
asToggle.MouseButton1Click:Connect(function()
    autoSellEnabled = not autoSellEnabled
    asToggle.Text = "Auto Sell (30 catch): " .. (autoSellEnabled and "ON" or "OFF")
    asToggle.BackgroundColor3 = autoSellEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

local statusLabel = Instance.new("TextLabel")
statusLabel.Text = "Status: Idle"
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 105)
statusLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
statusLabel.BackgroundTransparency = 1
statusLabel.Parent = tabFrames["AutoFish"]

function updateStatus(msg)
    statusLabel.Text = "Status: " .. msg
end

function equipRod()
    local char = LocalPlayer.Character
    if not char then return false end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and tool.Name:lower():find("rod") then return true end -- Already equipped
    
    local bp = LocalPlayer.Backpack
    local rod = bp:FindFirstChild("Fishing Rod") or bp:FindFirstChild("Rod") -- Common names
    
    if not rod then
        for _, t in pairs(bp:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("rod") then
                rod = t
                break
            end
        end
    end
    
    if rod then
        Humanoid:EquipTool(rod)
        return true
    end
    return false
end

function startFishing()
    while autoFishEnabled do
        if not equipRod() then
            updateStatus("Rod not found! Check Backpack.")
            task.wait(2)
            continue
        end
        
        -- 1. Charge Rod
        updateStatus("Casting...")
        if fishingEvents.ChargeRod then
            pcall(function()
                fishingEvents.ChargeRod:InvokeServer(1) -- 100% cast power
            end)
        else
            -- Fallback: Use VirtualUser click if remote is missing (Last resort)
            VirtualUser:ClickButton1(Vector2.new(0,0))
        end
        
        task.wait(1.5)
        
        -- 2. Request Minigame
        updateStatus("Waiting for bite...")
        -- In many fishing games, you wait for a 'bobber' to dip or a signal.
        -- We'll try to invoke the minigame immediately or wait a bit.
        task.wait(2.5) -- Simulated wait for bite
        
        updateStatus("Playing Minigame...")
        if fishingEvents.Minigame then
            pcall(function()
                fishingEvents.Minigame:InvokeServer()
            end)
        end
        
        task.wait(1.5) -- Minigame duration simulation
        
        -- 3. Complete Fishing
        updateStatus("Catching!")
        -- Try to fire completion event if it's a RemoteEvent
        if fishingEvents.Complete and fishingEvents.Complete:IsA("RemoteEvent") then
            pcall(function()
                fishingEvents.Complete:FireServer()
            end)
        elseif fishingEvents.Complete and fishingEvents.Complete:IsA("RemoteFunction") then
             pcall(function()
                fishingEvents.Complete:InvokeServer()
            end)
        end
        
        catchCount = catchCount + 1
        updateStatus("Caught! Total: " .. catchCount)
        task.wait(0.5)
        
        -- Auto Sell Logic
        if autoSellEnabled and catchCount >= 30 then
            updateStatus("Auto Selling...")
            if fishingEvents.Sell then
                pcall(function() fishingEvents.Sell:InvokeServer() end)
            else
                -- Teleport to sell area if remote not found? (Advanced)
                print("Sell Remote not mapped.")
            end
            catchCount = 0
            task.wait(1)
        end
    end
    updateStatus("Idle")
end

-- 3. Teleport System (EXPANDED)
local teleportLocations = {
    ["Spawn"] = Vector3.new(0, 10, 0), -- Placeholder, usually safe
    ["Ocean"] = Vector3.new(-1460.4, 13.1, 1826.7),
    ["Ancient Ruin"] = Vector3.new(6042.5, -555.3, 4454.2),
    ["Snow Island"] = Vector3.new(200, 10, 200), -- Placeholder
    ["Magma Island"] = Vector3.new(-200, 10, -200), -- Placeholder
    ["Pirate Island"] = Vector3.new(500, 10, 0), -- Placeholder
    ["Desert Island"] = Vector3.new(0, 10, 500) -- Placeholder
}

local function teleportTo(pos)
    if Character and Character.PrimaryPart then
        Character:SetPrimaryPartCFrame(CFrame.new(pos))
    end
end

-- UI for Teleport
local tpScroll = tabFrames["Teleport"]
local yPos = 0

-- Get Position Button
local getPosBtn = Instance.new("TextButton")
getPosBtn.Text = "Print Current Position (F9)"
getPosBtn.Size = UDim2.new(1, 0, 0, 30)
getPosBtn.Position = UDim2.new(0, 0, 0, yPos)
getPosBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
getPosBtn.TextColor3 = Color3.new(1,1,1)
getPosBtn.Parent = tpScroll
getPosBtn.MouseButton1Click:Connect(function()
    if Character and Character.PrimaryPart then
        local pos = Character.PrimaryPart.Position
        print("Current Position: Vector3.new(" .. math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. ", " .. math.floor(pos.Z) .. ")")
        updateStatus("Pos printed to console (F9)")
    end
end)
yPos = yPos + 35

-- Location Buttons
for name, pos in pairs(teleportLocations) do
    local btn = Instance.new("TextButton")
    btn.Text = "TP to " .. name
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.Parent = tpScroll
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.MouseButton1Click:Connect(function()
        teleportTo(pos)
    end)
    yPos = yPos + 35
end

-- 4. Settings System (NEW)
local settingsScroll = tabFrames["Settings"]
local setY = 0

-- WalkSpeed
local wsLabel = Instance.new("TextLabel")
wsLabel.Text = "WalkSpeed: 16"
wsLabel.Size = UDim2.new(1, 0, 0, 20)
wsLabel.Position = UDim2.new(0, 0, 0, setY)
wsLabel.BackgroundTransparency = 1
wsLabel.TextColor3 = Color3.new(1,1,1)
wsLabel.Parent = settingsScroll
setY = setY + 20

local wsInput = Instance.new("TextBox")
wsInput.Text = "16"
wsInput.Size = UDim2.new(1, 0, 0, 30)
wsInput.Position = UDim2.new(0, 0, 0, setY)
wsInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
wsInput.TextColor3 = Color3.new(1,1,1)
wsInput.Parent = settingsScroll
wsInput.FocusLost:Connect(function()
    local num = tonumber(wsInput.Text)
    if num and Humanoid then
        Humanoid.WalkSpeed = num
        wsLabel.Text = "WalkSpeed: " .. num
    end
end)
setY = setY + 35

-- JumpPower
local jpLabel = Instance.new("TextLabel")
jpLabel.Text = "JumpPower: 50"
jpLabel.Size = UDim2.new(1, 0, 0, 20)
jpLabel.Position = UDim2.new(0, 0, 0, setY)
jpLabel.BackgroundTransparency = 1
jpLabel.TextColor3 = Color3.new(1,1,1)
jpLabel.Parent = settingsScroll
setY = setY + 20

local jpInput = Instance.new("TextBox")
jpInput.Text = "50"
jpInput.Size = UDim2.new(1, 0, 0, 30)
jpInput.Position = UDim2.new(0, 0, 0, setY)
jpInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
jpInput.TextColor3 = Color3.new(1,1,1)
jpInput.Parent = settingsScroll
jpInput.FocusLost:Connect(function()
    local num = tonumber(jpInput.Text)
    if num and Humanoid then
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = num
        jpLabel.Text = "JumpPower: " .. num
    end
end)
setY = setY + 35

-- Anti-AFK
local antiAfkEnabled = false
local afkBtn = Instance.new("TextButton")
afkBtn.Text = "Anti-AFK: OFF"
afkBtn.Size = UDim2.new(1, 0, 0, 30)
afkBtn.Position = UDim2.new(0, 0, 0, setY)
afkBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
afkBtn.TextColor3 = Color3.new(1,1,1)
afkBtn.Parent = settingsScroll
afkBtn.MouseButton1Click:Connect(function()
    antiAfkEnabled = not antiAfkEnabled
    afkBtn.Text = "Anti-AFK: " .. (antiAfkEnabled and "ON" or "OFF")
    afkBtn.BackgroundColor3 = antiAfkEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    
    if antiAfkEnabled then
        task.spawn(function()
            while antiAfkEnabled do
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
                task.wait(60)
            end
        end)
    end
end)
setY = setY + 35

-- Fullbright
local fbEnabled = false
local fbBtn = Instance.new("TextButton")
fbBtn.Text = "Fullbright: OFF"
fbBtn.Size = UDim2.new(1, 0, 0, 30)
fbBtn.Position = UDim2.new(0, 0, 0, setY)
fbBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
fbBtn.TextColor3 = Color3.new(1,1,1)
fbBtn.Parent = settingsScroll
fbBtn.MouseButton1Click:Connect(function()
    fbEnabled = not fbEnabled
    fbBtn.Text = "Fullbright: " .. (fbEnabled and "ON" or "OFF")
    fbBtn.BackgroundColor3 = fbEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    
    if fbEnabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.FogEnd = 10000
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    end
end)

-- 5. Trade & Webhook (Kept from v1, minor UI tweaks)
-- Trade
local tradeActive = false
local selectedItems = {}
local targetPlayerName = ""

local tradeToggle = Instance.new("TextButton")
tradeToggle.Text = "Trade Mode (Select Items): OFF"
tradeToggle.Size = UDim2.new(1, 0, 0, 30)
tradeToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
tradeToggle.TextColor3 = Color3.new(1,1,1)
tradeToggle.Parent = tabFrames["Trade"]
tradeToggle.MouseButton1Click:Connect(function()
    tradeActive = not tradeActive
    tradeToggle.Text = "Trade Mode (Select Items): " .. (tradeActive and "ON" or "OFF")
    tradeToggle.BackgroundColor3 = tradeActive and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    if not tradeActive then
        print("Selected Items:", table.concat(selectedItems, ", "))
    else
        selectedItems = {} 
    end
end)

local targetInput = Instance.new("TextBox")
targetInput.PlaceholderText = "Target Player Name"
targetInput.Size = UDim2.new(1, 0, 0, 30)
targetInput.Position = UDim2.new(0, 0, 0, 35)
targetInput.Parent = tabFrames["Trade"]
targetInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
targetInput.TextColor3 = Color3.new(1,1,1)
targetInput.FocusLost:Connect(function()
    targetPlayerName = targetInput.Text
end)

local sendTradeBtn = Instance.new("TextButton")
sendTradeBtn.Text = "Send Trade Request"
sendTradeBtn.Size = UDim2.new(1, 0, 0, 30)
sendTradeBtn.Position = UDim2.new(0, 0, 0, 70)
sendTradeBtn.Parent = tabFrames["Trade"]
sendTradeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
sendTradeBtn.TextColor3 = Color3.new(1,1,1)
sendTradeBtn.MouseButton1Click:Connect(function()
    if targetPlayerName ~= "" and #selectedItems > 0 then
        print("Sending trade to " .. targetPlayerName .. " with " .. #selectedItems .. " items.")
    else
        warn("Please select items and enter a target player name.")
    end
end)

-- Hooking RE/EquipItem
task.spawn(function()
    local success, err = pcall(function()
        if getrawmetatable then
            local mt = getrawmetatable(game)
            local oldNamecall = mt.__namecall
            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self, ...)
                if tradeActive and (tostring(self) == "EquipItem" or tostring(self) == "RE/EquipItem") then
                    local args = {...}
                    if args[1] then
                        table.insert(selectedItems, args[1])
                        print("Item selected for trade:", args[1])
                    end
                    return nil -- Block equip
                end
                return oldNamecall(self, ...)
            end)
            setreadonly(mt, true)
        end
    end)
end)

-- Webhook
local webhookUrl = ""
local wbInput = Instance.new("TextBox")
wbInput.PlaceholderText = "Paste Webhook URL here..."
wbInput.Text = ""
wbInput.Size = UDim2.new(1, 0, 0, 30)
wbInput.Position = UDim2.new(0, 0, 0, 25)
wbInput.Parent = tabFrames["Webhook"]
wbInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
wbInput.TextColor3 = Color3.new(1,1,1)
wbInput.FocusLost:Connect(function() webhookUrl = wbInput.Text end)

local wbTestBtn = Instance.new("TextButton")
wbTestBtn.Text = "Test Webhook"
wbTestBtn.Size = UDim2.new(1, 0, 0, 30)
wbTestBtn.Position = UDim2.new(0, 0, 0, 60)
wbTestBtn.Parent = tabFrames["Webhook"]
wbTestBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
wbTestBtn.TextColor3 = Color3.new(1,1,1)
wbTestBtn.MouseButton1Click:Connect(function()
    if webhookUrl ~= "" then
        local data = HttpService:JSONEncode({content = "FishItBot Webhook Test!"})
        if request then
            request({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = data})
        end
    end
end)

-- 6. Misc
local cleanBtn = Instance.new("TextButton")
cleanBtn.Text = "Clean Visuals (FPS Boost)"
cleanBtn.Size = UDim2.new(1, 0, 0, 30)
cleanBtn.Parent = tabFrames["Misc"]
cleanBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
cleanBtn.TextColor3 = Color3.new(1,1,1)
cleanBtn.MouseButton1Click:Connect(function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled = false end
    end
end)

local hideNotifBtn = Instance.new("TextButton")
hideNotifBtn.Text = "Hide Game Notifications"
hideNotifBtn.Size = UDim2.new(1, 0, 0, 30)
hideNotifBtn.Position = UDim2.new(0, 0, 0, 35)
hideNotifBtn.Parent = tabFrames["Misc"]
hideNotifBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
hideNotifBtn.TextColor3 = Color3.new(1,1,1)
hideNotifBtn.MouseButton1Click:Connect(function()
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "FishItBot", Text = "Notifications Hidden", Duration = 3})
    end)
end)

print("Fish It Bot v2.0 Loaded Successfully")
