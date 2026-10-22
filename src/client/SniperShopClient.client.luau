local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyEvent = remotes:WaitForChild("BuySniperItem") :: RemoteEvent
local phaseEvent = remotes:WaitForChild("UpdatePhase") :: RemoteEvent
local currentPhase = ""

local gui = Instance.new("ScreenGui")
gui.Name = "SniperShopGui"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(520, 300)
panel.BackgroundColor3 = Color3.fromRGB(14, 10, 12)
panel.BorderColor3 = Color3.fromRGB(180, 35, 45)
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "SNIPER SHOP  |  PRESS B TO CLOSE"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = panel

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Position = UDim2.new(1, -210, 0, 14)
coinsLabel.Size = UDim2.fromOffset(190, 28)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextColor3 = Color3.fromRGB(255, 190, 90)
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextSize = 16
coinsLabel.TextXAlignment = Enum.TextXAlignment.Right
coinsLabel.Parent = panel

local function updateCoins()
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	coinsLabel.Text = if coins and coins:IsA("IntValue")
		then tostring(coins.Value) .. " COINS"
		else "0 COINS"
end

local function addButton(text: string, itemId: string, position: UDim2)
	local button = Instance.new("TextButton")
	button.Position = position
	button.Size = UDim2.fromOffset(230, 170)
	button.BackgroundColor3 = Color3.fromRGB(38, 22, 25)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.Text = text
	button.Parent = panel
	button.Activated:Connect(function()
		if gui.Enabled then buyEvent:FireServer(itemId) end
	end)
end

addButton("ONE-SHOT ROUNDS\n400 COINS", "OneShotRounds", UDim2.fromOffset(20, 80))
addButton("HIDDEN TRAPS\n250 COINS", "HiddenTraps", UDim2.fromOffset(270, 80))

local function canToggle()
	return currentPhase == "SafeZone" and player:GetAttribute("Role") == "Sniper"
end

phaseEvent.OnClientEvent:Connect(function(phaseName: string)
	currentPhase = phaseName
	if phaseName ~= "SafeZone" then gui.Enabled = false end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.B and canToggle() then
		gui.Enabled = not gui.Enabled
		updateCoins()
	end
end)

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	local coins = leaderstats and leaderstats:WaitForChild("Coins", 10)
	if coins and coins:IsA("IntValue") then
		coins.Changed:Connect(updateCoins)
		updateCoins()
	end
end)
