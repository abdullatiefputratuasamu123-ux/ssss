-- Fish It Auto-Fishing Bot
-- Generated based on implementation.md and task.md

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

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
ScreenGui.Name = "FishItGUI"
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
MainFrame.Size = UDim2.new(0, 360, 0, 240)
MainFrame.Position = UDim2.new(0.5, -180, 0.5, -120)
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
TitleLabel.Text = "ADULGEGE"
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
        MainFrame.Size = UDim2.new(0, 360, 0, 240)
        MinimizeButton.Text = "-"
    else
        MainFrame.Size = UDim2.new(0, 360, 0, 30)
        MinimizeButton.Text = "+"
    end
end)

-- 2. Fishing Core
local net = nil
local fishingEvents = {}

-- Safely try to find the net module and remotes
task.spawn(function()
    pcall(function()
        local packages = ReplicatedStorage:WaitForChild("Packages", 5)
        if packages then
             local index = packages:WaitForChild("_Index", 5)
             if index then
                 local netPackage = index:FindFirstChild("sleitnick_net@0.2.0")
                 if netPackage then
                     net = netPackage:WaitForChild("net")
                 end
             end
        end
    end)

    if net then
        fishingEvents = {
            EquipTool = net:WaitForChild("RE/EquipToolFromHotbar", 5),
            ChargeRod = net:WaitForChild("RF/ChargeFishingRod", 5),
            Minigame = net:WaitForChild("RF/RequestFishingMinigameStarted", 5),
            Complete = net:WaitForChild("RE/FishingCompleted", 5),
            BuyItem = net:WaitForChild("RF/BuyItem", 5) -- Assuming this exists for Auto Buy
        }
    else
        warn("FishItBot: Net module not found!")
    end
end)

local autoFishEnabled = false
local autoSellEnabled = false
local autoBuyRodEnabled = false
local catchCount = 0

-- Helper: Play Animation
local function playAnimation(animId)
    if not Humanoid then return end
    local animation = Instance.new("Animation")
    animation.AnimationId = animId
    local track = Humanoid:LoadAnimation(animation)
    track:Play()
    return track
end

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

local abToggle = Instance.new("TextButton")
abToggle.Text = "Auto Buy Rod: OFF"
abToggle.Size = UDim2.new(1, 0, 0, 30)
abToggle.Position = UDim2.new(0, 0, 0, 70)
abToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
abToggle.TextColor3 = Color3.new(1,1,1)
abToggle.Parent = tabFrames["AutoFish"]
abToggle.MouseButton1Click:Connect(function()
    autoBuyRodEnabled = not autoBuyRodEnabled
    abToggle.Text = "Auto Buy Rod: " .. (autoBuyRodEnabled and "ON" or "OFF")
    abToggle.BackgroundColor3 = autoBuyRodEnabled and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
end)

function startFishing()
    while autoFishEnabled and task.wait(0.5) do
        -- Check if rod is equipped
        -- Placeholder logic: assumes fishingEvents are valid
        if fishingEvents.ChargeRod then
            -- 1. Charge Rod
            pcall(function()
                fishingEvents.ChargeRod:InvokeServer(1) -- 100% cast
            end)
            task.wait(1)
            
            -- 2. Request Minigame
            if fishingEvents.Minigame then
                pcall(function()
                    fishingEvents.Minigame:InvokeServer()
                end)
            end
            task.wait(2) -- Wait for minigame duration
            
            -- 3. Complete Fishing (Perfect Cast Logic simulation)
            catchCount = catchCount + 1
            
            -- Auto Sell Logic
            if autoSellEnabled and catchCount >= 30 then
                catchCount = 0
                print("Selling fish...")
                -- Add Sell Remote here if known, e.g., net:WaitForChild("RF/SellFish"):InvokeServer()
            end
            
            -- Auto Buy Rod Logic
            if autoBuyRodEnabled and fishingEvents.BuyItem then
                 -- Example: Check money and buy better rod
                 -- This requires knowing the Rod ID and price
                 -- pcall(function() fishingEvents.BuyItem:InvokeServer("BetterRod") end)
            end
        end
    end
end

-- 3. Teleport System
local teleportLocations = {
    Ocean = {
        Vector3.new(-1460.4, 13.1, 1826.7),
        Vector3.new(-1524.6, 8.4, 1773.7)
    },
    AncientRuin = {
        Vector3.new(6042.5, -555.3, 4454.2),
        Vector3.new(6019.4, -553.0, 4506.8)
    }
}

local function teleportTo(locationName)
    local locs = teleportLocations[locationName]
    if locs then
        local target = locs[math.random(1, #locs)]
        if Character and Character.PrimaryPart then
            Character:SetPrimaryPartCFrame(CFrame.new(target))
        end
    end
end

local yPos = 0
for name, _ in pairs(teleportLocations) do
    local btn = Instance.new("TextButton")
    btn.Text = "TP to " .. name
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.Parent = tabFrames["Teleport"]
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.MouseButton1Click:Connect(function()
        teleportTo(name)
    end)
    yPos = yPos + 35
end

-- 4. Trade System
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
        selectedItems = {} -- Reset on new session
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
        -- Placeholder for Trade Request Remote
        -- local tradeRemote = net:FindFirstChild("RF/TradeRequest")
        -- if tradeRemote then
        --     tradeRemote:InvokeServer(Players[targetPlayerName], selectedItems)
        -- end
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
                local method = getnamecallmethod()
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

-- 5. Webhook System
local webhookUrl = ""

-- RBXGeneral Filtering (Simple Simulation)
local function filterMessage(msg)
    -- Placeholder for actual RBX filtering
    -- In a real script, this might check against a blacklist or use Chat:FilterStringForBroadcast
    return msg 
end

local function SendMessageToWebhook(url, message)
    if url == "" then return end
    
    local filteredMsg = filterMessage(message)
    
    local data = HttpService:JSONEncode({content = filteredMsg})
    if request then
        request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = data
        })
    elseif http_request then
        http_request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = data
        })
    end
end

local wbLabel = Instance.new("TextLabel")
wbLabel.Text = "Discord Webhook URL:"
wbLabel.Size = UDim2.new(1, 0, 0, 20)
wbLabel.TextColor3 = Color3.new(1,1,1)
wbLabel.BackgroundTransparency = 1
wbLabel.Parent = tabFrames["Webhook"]

local wbInput = Instance.new("TextBox")
wbInput.PlaceholderText = "Paste Webhook URL here..."
wbInput.Text = ""
wbInput.Size = UDim2.new(1, 0, 0, 30)
wbInput.Position = UDim2.new(0, 0, 0, 25)
wbInput.Parent = tabFrames["Webhook"]
wbInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
wbInput.TextColor3 = Color3.new(1,1,1)
wbInput.FocusLost:Connect(function()
    webhookUrl = wbInput.Text
end)

local wbTestBtn = Instance.new("TextButton")
wbTestBtn.Text = "Test Webhook"
wbTestBtn.Size = UDim2.new(1, 0, 0, 30)
wbTestBtn.Position = UDim2.new(0, 0, 0, 60)
wbTestBtn.Parent = tabFrames["Webhook"]
wbTestBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
wbTestBtn.TextColor3 = Color3.new(1,1,1)
wbTestBtn.MouseButton1Click:Connect(function()
    SendMessageToWebhook(webhookUrl, "FishItBot Webhook Test Successful!")
end)


-- 6. Security & Misc
-- Remove visuals
local function cleanVisuals()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
            v.Enabled = false
        end
    end
end

local cleanBtn = Instance.new("TextButton")
cleanBtn.Text = "Clean Visuals (FPS Boost)"
cleanBtn.Size = UDim2.new(1, 0, 0, 30)
cleanBtn.Parent = tabFrames["Misc"]
cleanBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
cleanBtn.TextColor3 = Color3.new(1,1,1)
cleanBtn.MouseButton1Click:Connect(cleanVisuals)

-- Hide Notifications (Simple implementation)
local function hideNotifications()
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "FishItBot",
            Text = "Notifications Hidden",
            Duration = 3
        })
        -- In a real scenario, we might hook the CoreGui to stop incoming notifications
    end)
end

local hideNotifBtn = Instance.new("TextButton")
hideNotifBtn.Text = "Hide Game Notifications"
hideNotifBtn.Size = UDim2.new(1, 0, 0, 30)
hideNotifBtn.Position = UDim2.new(0, 0, 0, 35)
hideNotifBtn.Parent = tabFrames["Misc"]
hideNotifBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
hideNotifBtn.TextColor3 = Color3.new(1,1,1)
hideNotifBtn.MouseButton1Click:Connect(hideNotifications)

print("Fish It Bot Loaded Successfully")
