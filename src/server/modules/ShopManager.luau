local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopManager = {}

type ShopItem = {
	Price: number,
}

local runnerItems: {[string]: ShopItem} = {
	SpeedBuff = { Price = 150 },
	Shield = { Price = 300 },
}

local sniperItems: {[string]: ShopItem} = {
	OneShotRounds = { Price = 400 },
	HiddenTraps = { Price = 250 },
}

local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function getOrCreateRemote(name: string): RemoteEvent
	local remote = remotes:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	local newRemote = Instance.new("RemoteEvent")
	newRemote.Name = name
	newRemote.Parent = remotes
	return newRemote
end

local buyRunnerItem = getOrCreateRemote("BuyItem")
local buySniperItem = getOrCreateRemote("BuySniperItem")

local function setupCoins(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	if not leaderstats:FindFirstChild("Coins") then
		local coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = 500
		coins.Parent = leaderstats
	end
end

local function purchase(player: Player, itemId: any, role: string, catalog: {[string]: ShopItem})
	if player:GetAttribute("Role") ~= role or typeof(itemId) ~= "string" then
		return
	end

	local item = catalog[itemId]
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if not item or not coins or not coins:IsA("IntValue") or coins.Value < item.Price then
		return
	end

	coins.Value -= item.Price
	if itemId == "SpeedBuff" then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.WalkSpeed = 24 end
	elseif itemId == "Shield" then
		player:SetAttribute("HasShield", true)
	elseif itemId == "OneShotRounds" then
		player:SetAttribute("HasOneShotRounds", true)
	elseif itemId == "HiddenTraps" then
		local count = player:GetAttribute("HiddenTrapInventory")
		player:SetAttribute("HiddenTrapInventory", (if typeof(count) == "number" then count else 0) + 1)
	end
end

function ShopManager.init()
	for _, player in Players:GetPlayers() do setupCoins(player) end
	Players.PlayerAdded:Connect(setupCoins)
	buyRunnerItem.OnServerEvent:Connect(function(player, itemId)
		purchase(player, itemId, "Runner", runnerItems)
	end)
	buySniperItem.OnServerEvent:Connect(function(player, itemId)
		purchase(player, itemId, "Sniper", sniperItems)
	end)
end

return ShopManager
