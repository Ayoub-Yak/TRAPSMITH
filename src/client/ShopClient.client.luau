local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyEvent = remotes:WaitForChild("BuyItem") :: RemoteEvent
local phaseEvent = remotes:WaitForChild("UpdatePhase") :: RemoteEvent
local shared = ReplicatedStorage:WaitForChild("Shared")
local catalog = require(shared:WaitForChild("ItemCatalog") :: ModuleScript)
local currentPhase = ""

local RED = Color3.fromRGB(255, 70, 85)
local DARK = Color3.fromRGB(18, 18, 22)
local PANEL = Color3.fromRGB(28, 28, 34)
local MUTED = Color3.fromRGB(165, 165, 175)

local shopGui = Instance.new("ScreenGui")
shopGui.Name = "ShopGui"
shopGui.ResetOnSpawn = false
shopGui.IgnoreGuiInset = true
shopGui.Enabled = false
shopGui.Parent = player:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.3
overlay.BorderSizePixel = 0
overlay.Parent = shopGui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(700, 430)
panel.BackgroundColor3 = DARK
panel.BorderColor3 = RED
panel.BorderSizePixel = 2
panel.Parent = overlay

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 52)
title.Position = UDim2.fromOffset(20, 18)
title.BackgroundTransparency = 1
title.Text = "RUNNER ARMORY"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 28
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.fromOffset(180, 30)
coinsLabel.Position = UDim2.new(1, -200, 0, 28)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextColor3 = RED
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextSize = 18
coinsLabel.TextXAlignment = Enum.TextXAlignment.Right
coinsLabel.Parent = panel

local cards = Instance.new("Frame")
cards.Size = UDim2.new(1, -40, 1, -130)
cards.Position = UDim2.fromOffset(20, 95)
cards.BackgroundTransparency = 1
cards.Parent = panel

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(310, 220)
layout.CellPadding = UDim2.fromOffset(20, 0)
layout.Parent = cards

local function updateCoins()
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	coinsLabel.Text = if coins and coins:IsA("IntValue") then tostring(coins.Value) .. " COINS" else " 0 COINS"
end

local function createItemCard(item)
	local card = Instance.new("Frame")
	card.Name = item.Id .. "Card"
	card.BackgroundColor3 = PANEL
	card.BorderColor3 = Color3.fromRGB(70, 70, 80)
	card.Parent = cards

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(64, 64)
	icon.Position = UDim2.fromOffset(16, 16)
	icon.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
	icon.Image = item.ImageId
	icon.Parent = card

	local itemTitle = Instance.new("TextLabel")
	itemTitle.Size = UDim2.new(1, -100, 0, 32)
	itemTitle.Position = UDim2.fromOffset(92, 18)
	itemTitle.BackgroundTransparency = 1
	itemTitle.Text = item.Name
	itemTitle.TextColor3 = Color3.new(1, 1, 1)
	itemTitle.Font = Enum.Font.GothamBold
	itemTitle.TextSize = 18
	itemTitle.TextXAlignment = Enum.TextXAlignment.Left
	itemTitle.Parent = card

	local description = Instance.new("TextLabel")
	description.Size = UDim2.new(1, -32, 0, 54)
	description.Position = UDim2.fromOffset(16, 88)
	description.BackgroundTransparency = 1
	description.Text = item.Description
	description.TextColor3 = MUTED
	description.Font = Enum.Font.Gotham
	description.TextSize = 13
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.Parent = card

	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(1, -32, 0, 44)
	buyButton.Position = UDim2.new(0, 16, 1, -58)
	buyButton.BackgroundColor3 = RED
	buyButton.BorderSizePixel = 0
	buyButton.Text = "BUY  " .. item.Price .. " COINS"
	buyButton.TextColor3 = Color3.new(1, 1, 1)
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextSize = 14
	buyButton.Parent = card
	buyButton.Activated:Connect(function()
		if shopGui.Enabled then
			buyEvent:FireServer(item.Id)
		end
	end)
end

for _, item in catalog.Runners do
	createItemCard(item)
end

local function canOpenShop(): boolean
	return currentPhase == "SafeZone" and player:GetAttribute("Role") == "Runner"
end

local function setShopVisible(visible: boolean)
	shopGui.Enabled = visible and canOpenShop()
	if shopGui.Enabled then updateCoins() end
end

phaseEvent.OnClientEvent:Connect(function(phaseName: string)
	currentPhase = phaseName
	if phaseName ~= "SafeZone" then setShopVisible(false) end
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.B and canOpenShop() then
		setShopVisible(not shopGui.Enabled)
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
