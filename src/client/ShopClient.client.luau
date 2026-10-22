local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyEvent = remotes:WaitForChild("BuyItem") :: RemoteEvent
local phaseEvent = remotes:WaitForChild("UpdatePhase") :: RemoteEvent
local currentPhase = ""

local gui = Instance.new("ScreenGui")
gui.Name = "ShopGui"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(520, 300)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
panel.BorderColor3 = Color3.fromRGB(255, 70, 85)
panel.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "RUNNER SHOP  |  PRESS B TO CLOSE"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = panel

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Position = UDim2.new(1, -210, 0, 14)
coinsLabel.Size = UDim2.fromOffset(190, 28)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextColor3 = Color3.fromRGB(255, 210, 90)
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextSize = 16
coinsLabel.TextXAlignment = Enum.TextXAlignment.Right
coinsLabel.Parent = panel

local function updateCoins()
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	coinsLabel.Text = if coins and coins:IsA("IntValue")
		then tostring(coins.Value) .. " COINS"
		else " 0 COINS"
end

local function addButton(text: string, itemId: string, position: UDim2)
	local button = Instance.new("TextButton")
	button.Position = position
	button.Size = UDim2.fromOffset(230, 170)
	button.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.Text = text
	button.Parent = panel
	button.Activated:Connect(function()
		if gui.Enabled then buyEvent:FireServer(itemId) end
	end)
end

addButton("SPEED BOOST\n150 COINS", "SpeedBuff", UDim2.fromOffset(20, 80))
addButton("BODY SHIELD\n300 COINS", "Shield", UDim2.fromOffset(270, 80))

local function canToggle()
	return currentPhase == "SafeZone" and player:GetAttribute("Role") == "Runner"
local LocalPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyEvent = remotes:WaitForChild("BuyItem") :: RemoteEvent
local phaseEvent = remotes:WaitForChild("UpdatePhase") :: RemoteEvent

local RED = Color3.fromRGB(255, 70, 85)
local DARK = Color3.fromRGB(18, 18, 22)
local PANEL = Color3.fromRGB(28, 28, 34)
local MUTED = Color3.fromRGB(165, 165, 175)

local shopGui = Instance.new("ScreenGui")
shopGui.Name = "ShopGui"
shopGui.ResetOnSpawn = false
shopGui.IgnoreGuiInset = true
shopGui.Enabled = false
shopGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.3
overlay.BorderSizePixel = 0
overlay.Parent = shopGui

local panel = Instance.new("Frame")
panel.Name = "ShopPanel"
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

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -40, 0, 24)
subtitle.Position = UDim2.fromOffset(20, 65)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Spend Coins before the hunt begins"
subtitle.TextColor3 = MUTED
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = panel

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.fromOffset(180, 30)
coinsLabel.Position = UDim2.new(1, -200, 0, 28)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextColor3 = RED
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextSize = 18
coinsLabel.TextXAlignment = Enum.TextXAlignment.Right
coinsLabel.Parent = panel

local closeHint = Instance.new("TextLabel")
closeHint.Size = UDim2.new(1, -40, 0, 24)
closeHint.Position = UDim2.new(0, 20, 1, -36)
closeHint.BackgroundTransparency = 1
closeHint.Text = "Press B to close"
closeHint.TextColor3 = MUTED
closeHint.Font = Enum.Font.Gotham
closeHint.TextSize = 13
closeHint.TextXAlignment = Enum.TextXAlignment.Right
closeHint.Parent = panel

local function updateCoins()
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		coinsLabel.Text = tostring(coins.Value) .. " COINS"
	else
		coinsLabel.Text = " 0 COINS "
	end
end

local function makeItemCard(itemId: string, itemName: string, price: number, description: string, position: UDim2)
	local card = Instance.new("Frame")
	card.Name = itemId .. "Card"
	card.Position = position
	card.Size = UDim2.fromOffset(310, 220)
	card.BackgroundColor3 = PANEL
	card.BorderColor3 = Color3.fromRGB(70, 70, 80)
	card.BorderSizePixel = 1
	card.Parent = panel

	local itemTitle = Instance.new("TextLabel")
	itemTitle.Size = UDim2.new(1, -32, 0, 32)
	itemTitle.Position = UDim2.fromOffset(16, 18)
	itemTitle.BackgroundTransparency = 1
	itemTitle.Text = itemName
	itemTitle.TextColor3 = Color3.new(1, 1, 1)
	itemTitle.Font = Enum.Font.GothamBold
	itemTitle.TextSize = 20
	itemTitle.TextXAlignment = Enum.TextXAlignment.Left
	itemTitle.Parent = card

	local itemDescription = Instance.new("TextLabel")
	itemDescription.Size = UDim2.new(1, -32, 0, 52)
	itemDescription.Position = UDim2.fromOffset(16, 62)
	itemDescription.BackgroundTransparency = 1
	itemDescription.Text = description
	itemDescription.TextColor3 = MUTED
	itemDescription.Font = Enum.Font.Gotham
	itemDescription.TextSize = 14
	itemDescription.TextWrapped = true
	itemDescription.TextXAlignment = Enum.TextXAlignment.Left
	itemDescription.TextYAlignment = Enum.TextYAlignment.Top
	itemDescription.Parent = card

	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(1, -32, 0, 48)
	buyButton.Position = UDim2.new(0, 16, 1, -64)
	buyButton.BackgroundColor3 = RED
	buyButton.BorderSizePixel = 0
	buyButton.Text = "BUY  " .. tostring(price) .. " COINS"
	buyButton.TextColor3 = Color3.new(1, 1, 1)
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextSize = 15
	buyButton.Parent = card

	buyButton.Activated:Connect(function()
		if shopGui.Enabled then
			buyEvent:FireServer(itemId)
		end
	end)
end

makeItemCard("SpeedBuff", "SPEED BOOST", 150, "Increase movement speed to 24 for the round.", UDim2.fromOffset(20, 115))
makeItemCard("Shield", "BODY SHIELD", 300, "Protect your Runner with a round shield.", UDim2.fromOffset(370, 115))

local currentPhase = ""
local function canOpenShop(): boolean
	return currentPhase == "SafeZone" and LocalPlayer:GetAttribute("Role") == "Runner"
end

local function setShopVisible(visible: boolean)
	shopGui.Enabled = visible and canOpenShop()
	if shopGui.Enabled then
		updateCoins()
	end
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
	if phaseName ~= "SafeZone" then
		setShopVisible(false)
	end
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed or input.KeyCode ~= Enum.KeyCode.B then
		return
	end

	if canOpenShop() then
		setShopVisible(not shopGui.Enabled)
	end
end)

local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
if leaderstats then
	local coins = leaderstats:WaitForChild("Coins", 10)
	if coins and coins:IsA("IntValue") then
		coins.Changed:Connect(updateCoins)
	end
end
