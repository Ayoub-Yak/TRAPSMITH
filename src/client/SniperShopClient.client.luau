local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyEvent = remotes:WaitForChild("BuySniperItem") :: RemoteEvent
local phaseEvent = remotes:WaitForChild("UpdatePhase") :: RemoteEvent

local ACCENT = Color3.fromRGB(180, 35, 45)
local DARK = Color3.fromRGB(12, 10, 12)
local PANEL = Color3.fromRGB(30, 20, 22)
local MUTED = Color3.fromRGB(170, 150, 155)

local shopGui = Instance.new("ScreenGui")
shopGui.Name = "SniperShopGui"
shopGui.ResetOnSpawn = false
shopGui.IgnoreGuiInset = true
shopGui.Enabled = false
shopGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.28
overlay.BorderSizePixel = 0
overlay.Parent = shopGui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(700, 430)
panel.BackgroundColor3 = DARK
panel.BorderColor3 = ACCENT
panel.BorderSizePixel = 2
panel.Parent = overlay

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 52)
title.Position = UDim2.fromOffset(20, 18)
title.BackgroundTransparency = 1
title.Text = "SNIPER TACTICAL SUPPLY"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 26
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -40, 0, 24)
subtitle.Position = UDim2.fromOffset(20, 65)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Acquire tactical advantages before the hunt"
subtitle.TextColor3 = MUTED
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = panel

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.fromOffset(180, 30)
coinsLabel.Position = UDim2.new(1, -200, 0, 28)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextColor3 = Color3.fromRGB(230, 85, 95)
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
	coinsLabel.Text = if coins and coins:IsA("IntValue")
		then tostring(coins.Value) .. " COINS"
		else "0 COINS"
end

local function makeItemCard(
	itemId: string,
	itemName: string,
	price: number,
	description: string,
	position: UDim2
)
	local card = Instance.new("Frame")
	card.Name = itemId .. "Card"
	card.Position = position
	card.Size = UDim2.fromOffset(310, 220)
	card.BackgroundColor3 = PANEL
	card.BorderColor3 = Color3.fromRGB(90, 45, 50)
	card.BorderSizePixel = 1
	card.Parent = panel

	local itemTitle = Instance.new("TextLabel")
	itemTitle.Size = UDim2.new(1, -32, 0, 32)
	itemTitle.Position = UDim2.fromOffset(16, 18)
	itemTitle.BackgroundTransparency = 1
	itemTitle.Text = itemName
	itemTitle.TextColor3 = Color3.new(1, 1, 1)
	itemTitle.Font = Enum.Font.GothamBold
	itemTitle.TextSize = 19
	itemTitle.TextXAlignment = Enum.TextXAlignment.Left
	itemTitle.Parent = card

	local itemDescription = Instance.new("TextLabel")
	itemDescription.Size = UDim2.new(1, -32, 0, 60)
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
	buyButton.Size = UDim2.new(1, -32, 0, 48)
	buyButton.Position = UDim2.new(0, 16, 1, -64)
	buyButton.BackgroundColor3 = ACCENT
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

makeItemCard(
	"OneShotRounds",
	"ONE-SHOT ROUNDS",
	400,
	"Special ammunition placeholder for future custom bullet behavior.",
	UDim2.fromOffset(20, 115)
)
makeItemCard(
	"HiddenTraps",
	"HIDDEN TRAPS",
	250,
	"Adds one hidden trap to your inventory. 3D trap assets can be plugged in later.",
	UDim2.fromOffset(370, 115)
)

local currentPhase = ""
local function canOpenShop(): boolean
	return currentPhase == "SafeZone" and LocalPlayer:GetAttribute("Role") == "Sniper"
end

local function setShopVisible(visible: boolean)
	shopGui.Enabled = visible and canOpenShop()
	if shopGui.Enabled then
		updateCoins()
	end
end

phaseEvent.OnClientEvent:Connect(function(phaseName: string)
	currentPhase = phaseName
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
